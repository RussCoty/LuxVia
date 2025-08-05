//
//  BaseViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 17/05/2025.
//

import UIKit

extension UIViewController {
    @discardableResult
    func addWhiteHeader(height: CGFloat = 48) -> UIView {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = .white
        view.addSubview(header)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: height)
        ])

        return header
    }
}

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLoginLogoutButton()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLoginButton),
            name: .authStatusChanged,
            object: nil
        )
    }

    private func setupLoginLogoutButton() {
        let isGuest = UserDefaults.standard.bool(forKey: "guestMode")
        let title = (AuthManager.shared.authState == .loggedIn && !isGuest) ? "Logout" : "Login"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: title,
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }

    @objc func updateLoginButton() {
        print("🔄 updateLoginButton fired. Logged in =", AuthManager.shared.isLoggedIn)

        let isGuest = UserDefaults.standard.bool(forKey: "guestMode")
        let title = (AuthManager.shared.authState == .loggedIn && !isGuest) ? "Logout" : "Login"
        navigationItem.rightBarButtonItem?.title = title

        if AuthManager.shared.authState == .guest {
            print("👤 Guest mode active")
        }
    }

    @objc func logoutTapped() {
        print("✅ Running BaseViewController.logoutTapped")

        let isLoggedIn = AuthManager.shared.isLoggedIn
        let isGuest = UserDefaults.standard.bool(forKey: "guestMode")

        let title = (isLoggedIn && !isGuest) ? "Logout" : "Login"
        let message = (isLoggedIn && !isGuest)
            ? "Are you sure you want to log out?"
            : "Would you like to log in?"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if isLoggedIn && !isGuest {
            alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
                SessionManager.logout()
            })
        } else {
            alert.addAction(UIAlertAction(title: "Login", style: .default) { _ in
                let loginVC = NativeLoginViewController()
                   loginVC.modalPresentationStyle = .fullScreen
                   self.present(loginVC, animated: true)
                // Trigger login
                print("👉 Login button tapped – implement login flow.")
            })
        }


        present(alert, animated: true)
    }
}
