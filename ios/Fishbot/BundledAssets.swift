import Foundation
import WebKit

final class BundledAssets: NSObject, WKURLSchemeHandler {
    private let root = Bundle.main.resourceURL!.appendingPathComponent("public", isDirectory: true)
    private let mime: [String: String] = ["html":"text/html", "js":"text/javascript", "mjs":"text/javascript", "css":"text/css", "json":"application/json", "svg":"image/svg+xml", "png":"image/png", "jpg":"image/jpeg", "wasm":"application/wasm", "txt":"text/plain"]
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, url.scheme == "fishbot", url.host == "localhost" else {
            task.didFailWithError(URLError(.unsupportedURL)); return
        }
        let relative = url.path == "/" ? "index.html" : String(url.path.dropFirst())
        let file = root.appendingPathComponent(relative).standardizedFileURL
        guard file.path.hasPrefix(root.standardizedFileURL.path + "/"), !relative.contains("\\") else {
            task.didFailWithError(URLError(.noPermissionsToReadFile)); return
        }
        do {
            let data = try Data(contentsOf: file, options: .mappedIfSafe)
            task.didReceive(URLResponse(url: url, mimeType: mime[file.pathExtension] ?? "application/octet-stream", expectedContentLength: data.count, textEncodingName: ["html","css","js","mjs","json","svg","txt"].contains(file.pathExtension) ? "utf-8" : nil))
            task.didReceive(data)
            task.didFinish()
        } catch { task.didFailWithError(URLError(.fileDoesNotExist)) }
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
