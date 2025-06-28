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
        setupLogoutButton()
    }

    private func setupLogoutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }

    @objc func logoutTapped() {
        print("✅ Running BaseViewController.logoutTapped")

        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            SessionManager.logout()
        })
        present(alert, animated: true)
    }





}
