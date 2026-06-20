import SwiftUI
import WebKit

struct LoginWebView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = loadError {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sign in to Personal OS")
                        .font(.posDisplay(22))
                    Text(errorMessage)
                        .foregroundStyle(POSTheme.muted)
                    Button("Retry") { loadError = nil }
                        .buttonStyle(.borderedProminent)
                        .tint(POSTheme.primaryDark)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                LoginWebViewRepresentable(
                    loadError: $loadError,
                    onHandoff: { handoff in session.saveHandoff(handoff) }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(POSTheme.background)
    }
}

private struct LoginWebViewRepresentable: UIViewRepresentable {
    @Binding var loadError: String?
    let onHandoff: (POSMobileAuthHandoff) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(loadError: $loadError, onHandoff: onHandoff)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController.add(context.coordinator, name: "posAuth")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor(POSTheme.background)
        webView.scrollView.backgroundColor = webView.backgroundColor

        let loginURL = PersonalOSAppConfig.frontendPath("/login")
        webView.load(URLRequest(url: loginURL))
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var loadError: String?
        let onHandoff: (POSMobileAuthHandoff) -> Void
        weak var webView: WKWebView?

        init(loadError: Binding<String?>, onHandoff: @escaping (POSMobileAuthHandoff) -> Void) {
            _loadError = loadError
            self.onHandoff = onHandoff
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "posAuth" else { return }
            if let json = message.body as? String, let handoff = decodeHandoff(json) {
                onHandoff(handoff)
                return
            }
            if let dict = message.body as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: dict),
               let handoff = try? JSONDecoder().decode(POSMobileAuthHandoff.self, from: data) {
                onHandoff(handoff)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let path = webView.url?.path else { return }
            if path.contains("/dashboard") || path.contains("/inbox") || path == "/" {
                fetchToken(in: webView)
            }
        }

        private func fetchToken(in webView: WKWebView) {
            let script = """
            fetch('/api/auth/mobile/handoff', { credentials: 'include' })
              .then(r => r.json())
              .then(d => {
                if (!d.access_token || !d.refresh_token) {
                  window.webkit.messageHandlers.posAuth.postMessage('');
                  return;
                }
                window.webkit.messageHandlers.posAuth.postMessage(JSON.stringify(d));
              })
              .catch(() => window.webkit.messageHandlers.posAuth.postMessage(''));
            """
            webView.evaluateJavaScript(script)
        }

        private func decodeHandoff(_ json: String) -> POSMobileAuthHandoff? {
            guard !json.isEmpty, let data = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(POSMobileAuthHandoff.self, from: data)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        private func report(_ error: Error) {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
            loadError = error.localizedDescription
        }
    }
}
