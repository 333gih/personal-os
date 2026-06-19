import SwiftUI
import WebKit
import UIKit

struct WebAppView: View {
    var startURL: URL = PersonalOSAppConfig.frontendURL
    @State private var loadError: String?
    @State private var reloadToken = 0

    var body: some View {
        Group {
            if let errorMessage = loadError {
                WebAppFallbackView(message: errorMessage) {
                    loadError = nil
                    reloadToken += 1
                }
            } else {
                WebAppWebView(startURL: startURL, loadError: $loadError)
                    .id(reloadToken)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

private struct WebAppWebView: UIViewRepresentable {
    let startURL: URL
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(loadError: $loadError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = .default()

        let iosFlag = """
        window.__PERSONAL_OS_IOS_APP__=true;
        document.documentElement.classList.add('personal-os-ios');
        """
        config.userContentController.addUserScript(
            WKUserScript(
                source: iosFlag,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = (webView.value(forKey: "userAgent") as? String ?? "")
            + " PersonalOS-iOS/1.0"
        webView.isOpaque = true
        webView.backgroundColor = UIColor(red: 242 / 255, green: 238 / 255, blue: 232 / 255, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        let startURL = self.startURL
        webView.load(URLRequest(url: startURL))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var loadError: String?
        weak var webView: WKWebView?
        private var injectedConnectHosts = Set<String>()

        init(loadError: Binding<String?>) {
            _loadError = loadError
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Extension handoff must run in Safari (Web Extension APIs are not available in WKWebView).
            if url.path.contains("/extension/connect"),
               navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url?.absoluteString, url.contains("/extension/connect") else { return }
            let host = webView.url?.host ?? url
            guard !injectedConnectHosts.contains(host) else { return }
            injectedConnectHosts.insert(host)

            guard let scriptURL = Bundle.main.url(forResource: "connect-bridge", withExtension: "js"),
                  let source = try? String(contentsOf: scriptURL, encoding: .utf8) else {
                return
            }
            webView.evaluateJavaScript(source)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }
            loadError = error.localizedDescription
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }
            loadError = error.localizedDescription
        }
    }
}

private struct WebAppFallbackView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal OS")
                .font(.title2.bold())
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Story Tracker Safari extension is still available under Settings → Safari → Extensions after installing this app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .background(POSTheme.background)
    }
}
