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
                    onToken: { token in session.saveToken(token) }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(POSTheme.background)
    }
}

private struct LoginWebViewRepresentable: UIViewRepresentable {
    @Binding var loadError: String?
    let onToken: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(loadError: $loadError, onToken: onToken)
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
        let onToken: (String) -> Void
        weak var webView: WKWebView?

        init(loadError: Binding<String?>, onToken: @escaping (String) -> Void) {
            _loadError = loadError
            self.onToken = onToken
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "posAuth", let token = message.body as? String, !token.isEmpty else { return }
            onToken(token)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let path = webView.url?.path else { return }
            if path.contains("/dashboard") || path.contains("/inbox") || path == "/" {
                fetchToken(in: webView)
            }
        }

        private func fetchToken(in webView: WKWebView) {
            let script = """
            fetch('/api/auth/token', { credentials: 'include' })
              .then(r => r.json())
              .then(d => window.webkit.messageHandlers.posAuth.postMessage(d.access_token || ''))
              .catch(() => window.webkit.messageHandlers.posAuth.postMessage(''));
            """
            webView.evaluateJavaScript(script)
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
