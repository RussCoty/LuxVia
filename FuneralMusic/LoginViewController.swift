import Foundation
import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    var loginCheckTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Login"

        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        view.addSubview(webView)

        if let url = URL(string: "https://funeralmusic.co.uk/login") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        startLoginPolling()
    }

    func startLoginPolling() {
        loginCheckTimer?.invalidate()
        loginCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.fetchMembershipStatusAfterLogin()
        }
    }

    func stopLoginPolling() {
        loginCheckTimer?.invalidate()
        loginCheckTimer = nil
    }

    func fetchMembershipStatusAfterLogin() {
        guard let url = URL(string: "https://funeralmusic.co.uk/wp-json/funeralmusic/v1/membership-status") else { return }

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                print("🍪 WKWebView Cookie: \(cookie.name)=\(cookie.value)")
                HTTPCookieStorage.shared.setCookie(cookie)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let config = URLSessionConfiguration.default
            config.httpCookieStorage = HTTPCookieStorage.shared
            let session = URLSession(configuration: config)

            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Request error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("❌ No data received from membership status check")
                    return
                }

                if let responseText = String(data: data, encoding: .utf8) {
                    print("📦 Raw response: \(responseText)")
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ JSON parsing failed")
                    return
                }

                let isLoggedIn = json["is_logged_in"] as? Bool ?? false
                let isMember = json["is_member"] as? Bool ?? false

                print("✅ Parsed: isLoggedIn=\(isLoggedIn), isMember=\(isMember)")

                if isLoggedIn {
                    self.stopLoginPolling()
                    DispatchQueue.main.async {
                        self.finalizeLoginState(isMember: isMember)
                    }
                }
            }

            task.resume()
        }
    }


    func finalizeLoginState(isMember: Bool) {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(isMember, forKey: "isMember")
        let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate
        sceneDelegate?.showMainApp()
    }
}
