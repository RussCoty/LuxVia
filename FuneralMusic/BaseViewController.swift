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
            NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLoginButton),
            name: .authStatusChanged,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupLogoutButton()
    }


    private func setupLogoutButton() {
        let title = AuthManager.shared.isLoggedIn ? "Logout" : "Login"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: title,
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }

    @objc func logoutTapped() {
        print("✅ Running BaseViewController.logoutTapped")

        let title = AuthManager.shared.isLoggedIn ? "Logout" : "Login"
        let alert = UIAlertController(
            title: title,
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: title, style: .destructive) { _ in
            SessionManager.logout()
        })

        present(alert, animated: true)
    }

    @objc func updateLoginButton() {
        print("🔄 updateLoginButton fired. Logged in =", AuthManager.shared.isLoggedIn)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AuthManager.shared.isLoggedIn ? "Logout" : "Login",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }


}
