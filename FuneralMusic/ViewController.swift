//
//  ViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//

import UIKit
import WebKit
import AVFoundation

class ViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Inject custom CSS (optional)
        let customCSS = """
        .custom-header-media {
          // max-height: 60px !important;
          // overflow: hidden !important;
        }
        """
        let scriptSource = "var style = document.createElement('style'); style.innerHTML = `\(customCSS)`; document.head.appendChild(style);"
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let contentController = WKUserContentController()
        contentController.addUserScript(script)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: self.view.bounds, configuration: config)
        
        webView.navigationDelegate = self
        webView.customUserAgent = "FuneralMusicApp"
        view.addSubview(webView)

        if let url = URL(string: "https://funeralmusic.co.uk/how-it-works-130/") {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        setupStatusLabel()
        updateLoginStatusLabel()
    }

    // MARK: - Login Status Display

    func setupStatusLabel() {
        statusLabel.text = "Guest"
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = .systemGray
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alpha = 0.9

        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            statusLabel.heightAnchor.constraint(equalToConstant: 26),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    func updateLoginStatusLabel() {
        let isMember = UserDefaults.standard.bool(forKey: "isMember")
        DispatchQueue.main.async {
            self.statusLabel.text = isMember ? "Member" : "Guest"
            self.statusLabel.backgroundColor = isMember ? .systemGreen : .systemGray
        }
    }

    // MARK: - WebView Login Detection

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString.contains("/dashboard") == true {
            print("✅ Login detected in About tab")
            checkMembershipStatusFromWebView()
        }
    }

    // MARK: - Fetch Membership Status Using Cookies

    func checkMembershipStatusFromWebView() {
        guard let url = URL(string: "https://funeralmusic.co.uk/wp-json/funeralmusic/v1/membership-status") else { return }

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)

            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }

            let request = URLRequest(url: url)

            session.dataTask(with: request) { data, _, _ in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let isMember = json["is_member"] as? Bool else {
                    print("❌ Could not fetch or parse membership status")
                    return
                }

                print("✅ Membership confirmed: \(isMember)")
                UserDefaults.standard.set(isMember, forKey: "isMember")
                self.updateLoginStatusLabel()
            }.resume()
        }
    }
    // MARK: - Membership: Nonce → API

    func checkMembershipStatusUsingNonceFromPage() {
        webView.evaluateJavaScript("document.getElementById('nonce')?.innerText") { result, error in
            if let error = error {
                print("❌ JS error retrieving nonce: \(error.localizedDescription)")
            }

            guard let nonce = result as? String else {
                print("❌ Could not retrieve nonce from page — result was: \(String(describing: result))")
                return
            }

            print("✅ Retrieved nonce: \(nonce)")
            self.fetchMembershipStatusWithNonce(nonce)
        }
    }

    func fetchMembershipStatusWithNonce(_ nonce: String) {
        guard let url = URL(string: "https://funeralmusic.co.uk/wp-json/funeralmusic/v1/membership-status") else {
            print("❌ Invalid API URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(nonce, forHTTPHeaderField: "X-WP-Nonce")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
            }

            if let response = response as? HTTPURLResponse {
                print("🌐 API Status Code: \(response.statusCode)")
            }

            if let raw = String(data: data ?? Data(), encoding: .utf8) {
                print("📦 Raw Response: \(raw)")
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ JSON parsing failed")
                return
            }

            print("📬 Parsed JSON: \(json)")

            let isMember = json["is_member"] as? Bool ?? false
            print("✅ isMember result: \(isMember)")
            UserDefaults.standard.set(isMember, forKey: "isMember")

            DispatchQueue.main.async {
                self.updateLoginStatusLabel()
            }
        }.resume()
    }

}

