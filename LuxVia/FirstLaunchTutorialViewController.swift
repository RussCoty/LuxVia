import UIKit
//hopefully this will sync in the repo now with the root veriosn of this file deletd


class FirstLaunchTutorialViewController: UIViewController {
    private let steps = [
        ("Welcome to LuxVia!", "Let's take a quick tour of the app's main features."),
        ("Import Music", "Tap 'Import' to add your own audio files to your library."),
        ("Library", "View and manage your imported music in the Library tab."),
        ("Mini Player", "Control playback from anywhere using the Mini Player at the bottom."),
        ("Get Started!", "You're ready to explore LuxVia. Enjoy!")
    ]
    private var currentStep = 0
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let nextButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        setupUI()
        showStep(index: currentStep)
    }

    private func setupUI() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        descriptionLabel.font = UIFont.systemFont(ofSize: 18)
        descriptionLabel.textColor = .white
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)

        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        nextButton.setTitleColor(.systemYellow, for: .normal)
        nextButton.backgroundColor = .white
        nextButton.layer.cornerRadius = 8
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            nextButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func showStep(index: Int) {
        let step = steps[index]
        titleLabel.text = step.0
        descriptionLabel.text = step.1
        nextButton.setTitle(index == steps.count - 1 ? "Done" : "Next", for: .normal)
    }

    @objc private func nextTapped() {
        if currentStep < steps.count - 1 {
            currentStep += 1
            showStep(index: currentStep)
        } else {
            NotificationCenter.default.post(name: .didFinishFirstLaunchTutorial, object: nil)
            dismiss(animated: true, completion: nil)
        }
    }
}

// Notification extension for tutorial completion
extension Notification.Name {
    static let didFinishFirstLaunchTutorial = Notification.Name("didFinishFirstLaunchTutorial")
}
