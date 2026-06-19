import SwiftUI
import WebKit

struct WebAppView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = true
        webView.backgroundColor = UIColor(red: 18 / 255, green: 16 / 255, blue: 14 / 255, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        guard let indexURL = Bundle.main.url(forResource: "index", withExtension: "html") else {
            context.coordinator.loadError = "Missing index.html in app bundle."
            return webView
        }

        let resourcesRoot = indexURL.deletingLastPathComponent()
        webView.loadFileURL(indexURL, allowingReadAccessTo: resourcesRoot)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var loadError: String?
        private var injectedConnectHosts = Set<String>()

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
            loadError = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            loadError = error.localizedDescription
        }
    }
}
