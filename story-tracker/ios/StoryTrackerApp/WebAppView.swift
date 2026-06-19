import SwiftUI
import WebKit

private let appScheme = "storytracker-app"

/// Serves bundled web UI (index.html + assets) without fragile file:// module loading.
final class AppBundleSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let resourceBase = Bundle.main.resourceURL else {
            urlSchemeTask.didFailWithError(SchemeError.missingBundle)
            return
        }

        let rawPath = urlSchemeTask.request.url?.path ?? "/"
        let trimmed = rawPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let relativePath = trimmed.isEmpty ? "index.html" : trimmed
        let fileURL = resourceBase.appendingPathComponent(relativePath)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            urlSchemeTask.didFailWithError(SchemeError.notFound(relativePath))
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let mime = Self.mimeType(for: fileURL.pathExtension)
            let response = URLResponse(
                url: urlSchemeTask.request.url!,
                mimeType: mime,
                expectedContentLength: data.count,
                textEncodingName: mime.contains("text") ? "utf-8" : nil
            )
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": return "text/html"
        case "js", "mjs": return "application/javascript"
        case "css": return "text/css"
        case "json": return "application/json"
        case "png": return "image/png"
        case "svg": return "image/svg+xml"
        case "woff2": return "font/woff2"
        default: return "application/octet-stream"
        }
    }

    private enum SchemeError: LocalizedError {
        case missingBundle
        case notFound(String)

        var errorDescription: String? {
            switch self {
            case .missingBundle:
                return "App web resources are missing from the bundle."
            case .notFound(let path):
                return "Resource not found: \(path)"
            }
        }
    }
}

struct WebAppView: View {
    @State private var loadError: String?

    var body: some View {
        Group {
            if let loadError {
                WebAppFallbackView(message: loadError)
            } else {
                WebAppWebView(loadError: $loadError)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

private struct WebAppWebView: UIViewRepresentable {
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(loadError: $loadError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.setURLSchemeHandler(AppBundleSchemeHandler(), forURLScheme: appScheme)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = true
        webView.backgroundColor = UIColor(red: 18 / 255, green: 16 / 255, blue: 14 / 255, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        if Bundle.main.url(forResource: "index", withExtension: "html") == nil {
            loadError = "Missing index.html. Rebuild with npm run build:ios-app && sync:ios-app."
            return webView
        }

        if let startURL = URL(string: "\(appScheme)://localhost/index.html") {
            webView.load(URLRequest(url: startURL))
        } else {
            loadError = "Could not start in-app web UI."
        }

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

private struct WebAppFallbackView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Story Tracker")
                .font(.title2.bold())
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Safari extension may still work after enabling it in Settings → Safari → Extensions.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .background(Color(red: 18 / 255, green: 16 / 255, blue: 14 / 255))
        .foregroundStyle(.white)
    }
}
