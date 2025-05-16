import Foundation
import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!

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

    // MARK: - Detect login completion
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString.contains("/dashboard") == true {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            fetchMembershipStatusAfterLogin()
        }
    }

    // MARK: - Fetch Membership Using Session Cookies
    func fetchMembershipStatusAfterLogin() {
        guard let url = URL(string: "https://funeralmusic.co.uk/wp-json/funeralmusic/v1/membership-status") else { return }

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)

            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let task = session.dataTask(with: request) { data, _, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let isMember = json["is_member"] as? Bool else {
                    print("❌ Could not parse membership status: \(error?.localizedDescription ?? "unknown error")")
                    DispatchQueue.main.async {
                        self.showMainApp(isMember: false)
                    }
                    return
                }

                print("✅ Membership status: \(isMember)")
                DispatchQueue.main.async {
                    self.showMainApp(isMember: isMember)
                }
            }
            task.resume()
        }
    }

    // MARK: - Proceed to App
    func showMainApp(isMember: Bool) {
        UserDefaults.standard.set(isMember, forKey: "isMember")
        let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate
        sceneDelegate?.showMainApp()
    }
}
