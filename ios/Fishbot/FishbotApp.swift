import SwiftUI
import WebKit

@main
struct FishbotApp: App {
    @StateObject private var model = AppearanceModel()
    var body: some Scene {
        WindowGroup {
            FishbotView(model: model)
                .ignoresSafeArea(.container)
                .preferredColorScheme(model.theme)
        }
    }
}

final class AppearanceModel: ObservableObject {
    @Published var theme: ColorScheme? = nil
}

struct FishbotView: UIViewRepresentable {
    @ObservedObject var model: AppearanceModel
    func makeCoordinator() -> NativeBridge { NativeBridge(model: model) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.setURLSchemeHandler(BundledAssets(), forURLScheme: "fishbot")
        config.userContentController.addScriptMessageHandler(context.coordinator, contentWorld: .page, name: "fishbot")
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.scrollView.bounces = false
        view.isOpaque = false
        view.backgroundColor = .systemBackground
        view.scrollView.backgroundColor = .systemBackground
        view.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.webView = view
        view.load(URLRequest(url: URL(string: "fishbot://localhost/index.html")!))
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {}
    static func dismantleUIView(_ view: WKWebView, coordinator: NativeBridge) {
        view.configuration.userContentController.removeScriptMessageHandler(forName: "fishbot", contentWorld: .page)
        coordinator.cancelAll()
    }
}
