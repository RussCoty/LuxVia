//
//  NonceExtractor.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 16/05/2025.
//
// File: NonceExtractor.swift

import SwiftUI
import WebKit

struct WebViewWrapper: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Nothing to update dynamically
    }
}

class NonceExtractor: NSObject, ObservableObject, WKNavigationDelegate {
    private var webView: WKWebView!
    @Published var nonce: String?
    @Published var pageHTML: String?

    override init() {
        super.init()
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        loadPage()
    }

    func getWebView() -> WKWebView {
        return webView
    }

    func loadPage() {
        guard let url = URL(string: "https://funeralmusic.co.uk/how-it-works-130/") else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("📡 WebView finished loading, checking for nonce...")
        extractNonce()
    }

    private func extractNonce() {
        let js = """
        (function() {
            const div = document.getElementById('nonce');
            return div ? div.textContent : null;
        })();
        """
        webView.evaluateJavaScript(js) { [weak self] result, error in
            if let error = error {
                print("❌ JS Evaluation Error:", error.localizedDescription)
                return
            }
            if let nonce = result as? String {
                self?.nonce = nonce
                print("✅ Retrieved nonce:", nonce)
                self?.fetchPageHTML()
            } else {
                print("⚠️ Nonce not found.")
            }
        }
    }

    private func fetchPageHTML() {
        let htmlJS = "document.documentElement.outerHTML.toString();"
        webView.evaluateJavaScript(htmlJS) { [weak self] result, error in
            if let html = result as? String {
                self?.pageHTML = html
                print("📄 PAGE HTML:\n\(html.prefix(2000))...") // Trim long output
            } else if let error = error {
                print("❌ HTML Fetch Error:", error.localizedDescription)
            }
        }
    }
}
