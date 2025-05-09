//
//  LoginViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 06/05/2025.
//

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

    // Detect when login completes based on URL or cookies
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString.contains("/dashboard") == true {
            // Logged in
            UserDefaults.standard.set(true, forKey: "isLoggedIn")

            // Show main app
            let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate
            sceneDelegate?.showMainApp()
        }
    }
}
