import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var browser = CrateBrowser()

    var body: some View {
        ZStack {
            CrateWebView(browser: browser)
            if browser.isLoading {
                ProgressView().padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            if let failure = browser.loadFailure {
                VStack(spacing: 18) {
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                    Text(failure).multilineTextAlignment(.center)
                    Button(browser.tr("Yeniden dene", "Try again")) { browser.reload() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(24)
            }
        }
        .background(Color(red: 0.91, green: 0.94, blue: 0.95))
        .sheet(item: $browser.shareItem) { item in
            ShareSheet(fileURL: item.url)
        }
        .alert(browser.tr("Model paylaşılamadı", "Unable to share model"),
               isPresented: Binding(get: { browser.exportFailure != nil },
                                    set: { if !$0 { browser.exportFailure = nil } })) {
            Button("OK", role: .cancel) { browser.exportFailure = nil }
        } message: { Text(browser.exportFailure ?? "") }
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let fileURL: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
