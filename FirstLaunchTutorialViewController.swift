import UIKit

class FirstLaunchTutorialViewController: UIViewController {
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(continueButton)
        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    @objc private func continueTapped() {
        // Notify app to proceed to overlays/tutorial
        NotificationCenter.default.post(name: .didFinishFirstLaunchTutorial, object: nil)
    }
}

extension Notification.Name {
    static let didFinishFirstLaunchTutorial = Notification.Name("didFinishFirstLaunchTutorial")
}
