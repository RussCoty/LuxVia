//
//  TopBarView.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 17/05/2025.
//

import UIKit

class TopBarView: UIView {

    let logoutButton = UIButton(type: .system)
    let contentContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .systemBackground

        // Container for left/middle content
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentContainer)

        // Logout button setup
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(.systemBlue, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoutButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),

            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentContainer.trailingAnchor.constraint(lessThanOrEqualTo: logoutButton.leadingAnchor, constant: -8),

            logoutButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setContent(_ view: UIView) {
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor)
        ])
    }
}

// Usage Example (in your ViewController):
// let topBar = TopBarView()
// view.addSubview(topBar)
// topBar.translatesAutoresizingMaskIntoConstraints = false
// NSLayoutConstraint.activate([
//     topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//     topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//     topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
// ])
// topBar.logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
