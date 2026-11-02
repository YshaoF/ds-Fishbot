import Foundation
import WebKit
import SwiftUI
import UniformTypeIdentifiers

final class NoCrossOriginRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // Avoid ever forwarding a user-entered API Key to a redirected host.
        completionHandler(nil)
    }
}

final class NativeBridge: NSObject, WKScriptMessageHandlerWithReply, WKNavigationDelegate {
    weak var webView: WKWebView?
    private let model: AppearanceModel
    private let disk = DispatchQueue(label: "com.fishbot.storage", qos: .utility)
    private var tasks: [String: URLSessionDataTask] = [:]
    private let redirectDelegate = NoCrossOriginRedirects()
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 150
        config.httpCookieStorage = nil
        config.urlCache = nil
        return URLSession(configuration: config, delegate: redirectDelegate, delegateQueue: nil)
    }()
    init(model: AppearanceModel) { self.model = model; super.init() }
    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Fishbot", isDirectory: true).appendingPathComponent("state.json")
    }
    private func finish(_ callback: @escaping (Any?, String?) -> Void, _ value: Any) {
        DispatchQueue.main.async { callback(value, nil) }
    }
    private func fail(_ callback: @escaping (Any?, String?) -> Void, _ message: String) { finish(callback, ["error": message]) }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.scheme == "fishbot", message.frameInfo.request.url?.host == "localhost", let body = message.body as? [String: Any], let action = body["action"] as? String else {
            fail(replyHandler, "请求来源无效。"); return
        }
        switch action {
        case "storageRead":
            disk.async { [weak self] in
                guard let self else { return }
                do {
                    if !FileManager.default.fileExists(atPath: self.stateURL.path) { self.finish(replyHandler, ["value": NSNull()]); return }
                    let raw = try String(contentsOf: self.stateURL, encoding: .utf8)
                    self.finish(replyHandler, ["value": raw])
                } catch { self.fail(replyHandler, "无法读取本机数据，请保留现有数据并重新打开。") }
            }
        case "storageWrite":
            guard let value = body["value"] as? String, value.utf8.count <= 50 * 1024 * 1024, let data = value.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil else { fail(replyHandler, "保存数据无效或超过50MB，请先备份并清理附件。"); return }
            disk.async { [weak self] in
                guard let self else { return }
                do {
                    try FileManager.default.createDirectory(at: self.stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try data.write(to: self.stateURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                    self.finish(replyHandler, ["ok": true])
                } catch { self.fail(replyHandler, "本机保存失败，请检查剩余存储空间。") }
            }
        case "secretGet", "secretSet":
            guard let slot = body["slot"] as? String, slot.range(of: "^[a-zA-Z0-9_-]{1,100}$", options: .regularExpression) != nil else { fail(replyHandler, "Key 位置无效。"); return }
            disk.async { [weak self] in
                guard let self else { return }
                do {
                    if action == "secretGet" { self.finish(replyHandler, ["value": try SecretStore.get(slot)]) }
                    else {
                        guard let value = body["value"] as? String, value.count < 16000 else { self.fail(replyHandler, "Key 过长。"); return }
                        try SecretStore.set(slot, value); self.finish(replyHandler, ["ok": true])
                    }
                } catch let error as LocalError { self.fail(replyHandler, error.message) }
                catch { self.fail(replyHandler, "钥匙串操作失败。") }
            }
        case "appearance":
            model.theme = (body["theme"] as? String) == "dark" ? .dark : .light
            finish(replyHandler, ["ok": true])
        case "request": request(body, replyHandler)
        case "cancel":
            if let id = body["id"] as? String { tasks[id]?.cancel(); tasks.removeValue(forKey: id) }
            finish(replyHandler, ["ok": true])
        case "share":
            guard let text = body["text"] as? String, text.utf8.count <= 50 * 1024 * 1024 else { fail(replyHandler, "分享内容过大。"); return }
            let filename = ((body["filename"] as? String) ?? "Fishbot.txt").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\\", with: "_")
            do {
                let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let file = folder.appendingPathComponent(String(filename.prefix(160)))
                try text.write(to: file, atomically: true, encoding: .utf8)
                let sheet = UIActivityViewController(activityItems: [file], applicationActivities: nil)
                guard let controller = webView?.window?.rootViewController else { fail(replyHandler, "暂时无法打开分享面板。"); return }
                var top = controller
                while let presented = top.presentedViewController { top = presented }
                sheet.popoverPresentationController?.sourceView = webView
                sheet.popoverPresentationController?.sourceRect = CGRect(x: (webView?.bounds.midX ?? 0), y: (webView?.bounds.midY ?? 0), width: 1, height: 1)
                sheet.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: folder) }
                top.present(sheet, animated: true)
                finish(replyHandler, ["ok": true])
            } catch { fail(replyHandler, "无法创建分享文件。") }
        default: fail(replyHandler, "此操作不可用。")
        }
    }
    private func request(_ input: [String: Any], _ callback: @escaping (Any?, String?) -> Void) {
        guard let id = input["id"] as? String, id.count <= 100, tasks[id] == nil, tasks.count < 6, let raw = input["url"] as? String, let url = URL(string: raw), url.scheme == "https", let host = url.host, !host.isEmpty, url.user == nil, url.password == nil, url.fragment == nil else { fail(callback, "API 请求无效，请使用 HTTPS 地址。"); return }
        let method = (input["method"] as? String) ?? "GET"
        guard ["GET","POST"].contains(method), let text = input["body"] as? String, text.utf8.count <= 12 * 1024 * 1024 else { fail(callback, "API 内容过大或方法无效。"); return }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if method == "POST" { request.httpBody = Data(text.utf8) }
        if let headers = input["headers"] as? [String: String] {
            for (name, value) in headers where ["authorization","content-type","accept"].contains(name.lowercased()) && value.count < 16000 { request.setValue(value, forHTTPHeaderField: name) }
        }
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.tasks.removeValue(forKey: id)
                if error != nil { self.fail(callback, "网络请求未完成，请检查连接或重试。"); return }
                guard let http = response as? HTTPURLResponse, let data, data.count <= 8 * 1024 * 1024, let text = String(data: data, encoding: .utf8) else { self.fail(callback, "API 返回内容过大或格式无效。"); return }
                self.finish(callback, ["status": http.statusCode, "text": text])
            }
        }
        tasks[id] = task; task.resume()
    }
    func cancelAll() { tasks.values.forEach { $0.cancel() }; tasks.removeAll(); session.invalidateAndCancel() }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        #if targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains("--fishbot-selftest") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self, weak webView] in
            guard let self, let webView else { return }
            var report: [String: Any] = ["keychain": false, "uiReady": false, "storage": false]
            do {
                try SecretStore.set("qa-selftest", "synthetic-ci-key")
                report["keychain"] = try SecretStore.get("qa-selftest") == "synthetic-ci-key"
                try SecretStore.set("qa-selftest", "")
                let file = self.stateURL.deletingLastPathComponent().appendingPathComponent("qa-storage.txt")
                try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data("synthetic-storage".utf8).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                report["storage"] = try String(contentsOf: file, encoding: .utf8) == "synthetic-storage"
                try FileManager.default.removeItem(at: file)
            } catch { report["nativeError"] = String(describing: error) }
            webView.evaluateJavaScript("JSON.stringify({ready:!!document.querySelector('#welcome-card')||!!document.querySelector('#composer'),native:!!window.FishbotBridge?.native,bootError:document.querySelector('#boot-status')?.textContent||''})") { value, error in
                if let text = value as? String, let data = text.data(using: .utf8), let ui = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    report["uiReady"] = (ui["ready"] as? Bool) == true && (ui["native"] as? Bool) == true
                    report["ui"] = ui
                } else { report["uiError"] = error?.localizedDescription ?? "No UI result" }
                if let data = try? JSONSerialization.data(withJSONObject: report, options: .prettyPrinted) {
                    try? data.write(to: self.stateURL.deletingLastPathComponent().appendingPathComponent("selftest.json"), options: .atomic)
                }
            }
        }
        #endif
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.request.url?.scheme == "fishbot", navigationAction.request.url?.host == "localhost" else { decisionHandler(.cancel); return }
        decisionHandler(.allow)
    }
}
