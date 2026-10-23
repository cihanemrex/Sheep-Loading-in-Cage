import SwiftUI
import WebKit
import UIKit

final class CrateBrowser: ObservableObject {
    @Published var isLoading = true
    @Published var loadFailure: String?
    @Published var exportFailure: String?
    @Published var shareItem: ShareItem?
    weak var webView: WKWebView?
    var webDirectory: URL?

    var isTurkish: Bool {
        if let name = webView?.url?.lastPathComponent { return name != "en.html" }
        return Locale.preferredLanguages.first?.hasPrefix("tr") ?? true
    }

    func tr(_ turkish: String, _ english: String) -> String { isTurkish ? turkish : english }

    func reload() {
        loadFailure = nil
        guard let webView = webView, let directory = webDirectory else { return }
        isLoading = true
        let file = directory.appendingPathComponent(isTurkish ? "index.html" : "en.html")
        webView.loadFileURL(file, allowingReadAccessTo: directory)
    }
}

struct CrateWebView: UIViewRepresentable {
    @ObservedObject var browser: CrateBrowser

    func makeCoordinator() -> Coordinator { Coordinator(browser: browser) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.add(context.coordinator, name: "exportModel")
        config.userContentController.add(context.coordinator, name: "clientError")
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = UIColor(red: 0.91, green: 0.94, blue: 0.95, alpha: 1)
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.allowsBackForwardNavigationGestures = false
        browser.webView = view
        guard let directory = Bundle.main.resourceURL?.appendingPathComponent("Web"),
              FileManager.default.fileExists(atPath: directory.appendingPathComponent("index.html").path) else {
            DispatchQueue.main.async {
                browser.isLoading = false
                browser.loadFailure = browser.tr("Uygulamanın model dosyaları bulunamadı.", "Bundled model files could not be found.")
            }
            return view
        }
        browser.webDirectory = directory
        let file = directory.appendingPathComponent(browser.isTurkish ? "index.html" : "en.html")
        view.loadFileURL(file, allowingReadAccessTo: directory)
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.stopLoading()
        view.navigationDelegate = nil
        view.configuration.userContentController.removeScriptMessageHandler(forName: "exportModel")
        view.configuration.userContentController.removeScriptMessageHandler(forName: "clientError")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let browser: CrateBrowser
        init(browser: CrateBrowser) { self.browser = browser }

        private func isBundledFile(_ url: URL?) -> Bool {
            guard let url = url, url.isFileURL, let directory = browser.webDirectory else { return false }
            return url.standardizedFileURL.path.hasPrefix(directory.standardizedFileURL.path + "/")
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { decisionHandler(.cancel); return }
            if isBundledFile(url) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                // Reference links open in Safari and do not gain access to the native bridge.
                if action.navigationType == .linkActivated,
                   ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                    UIApplication.shared.open(url)
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            browser.isLoading = true
            browser.loadFailure = nil
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            browser.isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail(error) }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail(error) }
        private func fail(_ error: Error) {
            if (error as NSError).code == NSURLErrorCancelled { return }
            browser.isLoading = false
            browser.loadFailure = error.localizedDescription
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            browser.isLoading = false
            browser.loadFailure = browser.tr("Görüntüleyici durdu. Yeniden yükleyebilirsiniz.", "The viewer stopped. Please reload it.")
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame, isBundledFile(message.frameInfo.request.url) else { return }
            if message.name == "clientError" {
                browser.exportFailure = browser.tr("Model oluşturulamadı. Yeniden deneyin.", "The model could not be exported. Please try again.")
                return
            }
            guard message.name == "exportModel", browser.shareItem == nil,
                  let body = message.body as? [String: Any],
                  let encoded = body["base64"] as? String, encoded.utf8.count < 10_000_000,
                  let data = Data(base64Encoded: encoded), data.count >= 12,
                  Array(data.prefix(4)) == [0x67, 0x6c, 0x54, 0x46] else {
                browser.exportFailure = browser.tr("Geçerli bir GLB modeli alınamadı.", "A valid GLB model was not received.")
                return
            }
            do {
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("CrateExports", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let url = directory.appendingPathComponent("Sheep_Crate_300x225x100.glb")
                try data.write(to: url, options: .atomic)
                browser.shareItem = ShareItem(url: url)
            } catch { browser.exportFailure = error.localizedDescription }
        }
    }
}
