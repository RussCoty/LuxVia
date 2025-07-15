//
//  NativeLoginViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 16/05/2025.
//

import UIKit
import SafariServices

class NativeLoginViewController: UIViewController {

    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let guestButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        usernameField.placeholder = "Username or Email"
        usernameField.borderStyle = .roundedRect

        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect

        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        guestButton.setTitle("Try as Guest", for: .normal)
        guestButton.addTarget(self, action: #selector(guestTapped), for: .touchUpInside)

        registerButton.setTitle("Register", for: .normal)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [usernameField, passwordField, loginButton, guestButton, registerButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func loginTapped() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(message: "Please enter both username and password.")
            return
        }

        let url = URL(string: "https://funeralmusic.co.uk/wp-json/jwt-auth/v1/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(message: "Error: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Invalid response from server.")
                }
                return
            }

            if let token = json["token"] as? String {
                // Save token in Keychain
                if let tokenData = token.data(using: .utf8) {
                    KeychainHelper.standard.save(tokenData, service: "jwt", account: "funeralmusic")
                }


                // Set login status
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(true, forKey: "isMember") // assume true
                UserDefaults.standard.set(false, forKey: "guestMode")


                DispatchQueue.main.async {
                    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                        sceneDelegate.showMainApp()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let message = json["message"] as? String ?? "Login failed"
                    self.showAlert(message: message)
                }
            }
        }

        task.resume()
    }

    @objc private func guestTapped() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isMember")
        UserDefaults.standard.set(true, forKey: "guestMode") // 👈 NEW

        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.showMainApp()
        }
    }


    @objc private func registerTapped() {
        if let url = URL(string: "https://funeralmusic.co.uk/wp-login.php?action=register") {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true)
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Login", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
