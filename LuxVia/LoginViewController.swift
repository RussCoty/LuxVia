import Foundation
import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    var loginCheckTimer: Timer?
    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "LuxViaLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Login"

        setupLogo()
        animateLogo()
    }

    private func setupLogo() {
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func animateLogo() {
        UIView.animate(withDuration: 1.2, delay: 0.2, options: [.curveEaseOut], animations: {
            self.logoImageView.alpha = 1.0
            self.logoImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.logoImageView.transform = .identity
            }) { _ in
                self.logoImageView.removeFromSuperview()
                self.setupWebView()
            }
        }
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

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
        AuthManager.shared.login()
        UserDefaults.standard.set(isMember, forKey: "isMember")

        NotificationCenter.default.post(name: .authStatusChanged, object: nil)

        let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate
        sceneDelegate?.showMainApp()
    }
}
