//test 
import UIKit

class TopBarView: UIView {

    let logoutButton = UIButton(type: .system)
    let titleLabel = UILabel()
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

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentContainer)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(titleLabel)

        let isGuest = UserDefaults.standard.bool(forKey: "guestMode")
        logoutButton.setTitle((AuthManager.shared.isLoggedIn && !isGuest) ? "Logout" : "Login", for: .normal)
        logoutButton.setTitleColor(.systemBlue, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoutButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),

            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentContainer.trailingAnchor.constraint(lessThanOrEqualTo: logoutButton.leadingAnchor, constant: -8),

            titleLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),

            logoutButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Observer to update logout button when auth status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLogoutButton),
            name: .authStatusChanged,
            object: nil
        )
    }

    @objc private func updateLogoutButton() {
        let isGuest = UserDefaults.standard.bool(forKey: "guestMode")
        logoutButton.setTitle((AuthManager.shared.isLoggedIn && !isGuest) ? "Logout" : "Login", for: .normal)
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
    }
}
