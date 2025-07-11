import UIKit

class TopHeaderView: UIView {
    let segmentedControl: UISegmentedControl?
    let logoutButton = UIButton(type: .system)

    init(segments: [String]? = nil) {
        if let segments = segments {
            self.segmentedControl = UISegmentedControl(items: segments)
        } else {
            self.segmentedControl = nil
        }
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.segmentedControl = nil
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLogoutButton),
            name: .authStatusChanged,
            object: nil
        )

        backgroundColor = .systemGroupedBackground

        logoutButton.setTitle(AuthManager.shared.isLoggedIn ? "Logout" : "Login", for: .normal)
        logoutButton.setTitleColor(.systemBlue, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center

        if let segmentedControl = segmentedControl {
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            segmentedControl.setContentHuggingPriority(.required, for: .horizontal)

            segmentedControl.backgroundColor = .tertiarySystemGroupedBackground
            segmentedControl.selectedSegmentTintColor = .white
            segmentedControl.layer.cornerRadius = 8
            segmentedControl.clipsToBounds = true

            segmentedControl.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.systemBlue
            ], for: .normal)

            segmentedControl.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.label
            ], for: .selected)

            segmentedControl.heightAnchor.constraint(equalToConstant: 32).isActive = true

            row.addArrangedSubview(segmentedControl)
        }

        row.addArrangedSubview(logoutButton)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    @objc private func updateLogoutButton() {
        logoutButton.setTitle(AuthManager.shared.isLoggedIn ? "Logout" : "Login", for: .normal)
    }
}
