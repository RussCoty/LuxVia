import UIKit


class FirstLaunchTutorialViewController: UIViewController {
    struct TutorialStep {
        let title: String
        let description: String
    }

    private let steps: [TutorialStep] = [
        TutorialStep(title: "Welcome to LuxVia!", description: "Discover music, readings, and more. Let's take a quick tour."),
        TutorialStep(title: "Music Tab", description: "Browse and play curated music selections for your service."),
        TutorialStep(title: "Custom Readings", description: "Create and manage personalized readings for your ceremony."),
        TutorialStep(title: "Lyrics Sync", description: "View synced lyrics while music plays for a seamless experience."),
        TutorialStep(title: "PDF Booklet", description: "Generate and preview a PDF booklet for your event."),
        TutorialStep(title: "Get Started!", description: "You're ready to explore LuxVia. Enjoy!")
    ]

    private var currentStep = 0

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        updateStep()
    }

    private func updateStep() {
        let step = steps[currentStep]
        titleLabel.text = step.title
        descriptionLabel.text = step.description
        if currentStep == steps.count - 1 {
            continueButton.setTitle("Finish", for: .normal)
        } else {
            continueButton.setTitle("Next", for: .normal)
        }
    }

    @objc private func continueTapped() {
        if currentStep < steps.count - 1 {
            currentStep += 1
            updateStep()
        } else {
            NotificationCenter.default.post(name: .didFinishFirstLaunchTutorial, object: nil)
        }
    }
}

extension Notification.Name {
    static let didFinishFirstLaunchTutorial = Notification.Name("didFinishFirstLaunchTutorial")
}
