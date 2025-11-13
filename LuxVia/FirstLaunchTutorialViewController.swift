import UIKit

struct TutorialStep {
    let title: String
    let description: String
    let imageName: String?
    let isLastStep: Bool
    
    init(title: String, description: String, imageName: String? = nil, isLastStep: Bool = false) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.isLastStep = isLastStep
    }
}

class FirstLaunchTutorialViewController: UIViewController {
    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "Welcome to LuxVia! 🎵",
            description: "Your complete funeral music and service companion. Let's take a guided tour to get you started.",
            imageName: "music.note.list"
        ),
        TutorialStep(
            title: "Words & Readings 📖",
            description: "Browse through a comprehensive library of funeral readings, prayers, and meaningful words for your service.",
            imageName: "book"
        ),
        TutorialStep(
            title: "Music Library 🎼",
            description: "Import your own music files or browse curated funeral music. Search, organize, and preview tracks easily.",
            imageName: "music.note.list"
        ),
        TutorialStep(
            title: "Service Planning 📋",
            description: "Create and organize your funeral service order. Add music, readings, and generate beautiful service booklets.",
            imageName: "music.note"
        ),
        TutorialStep(
            title: "Audio Controls 🎛️",
            description: "Use the mini player at the bottom to control music playback. Features fade in/out, cue points, and seamless transitions.",
            imageName: "play.circle"
        ),
        TutorialStep(
            title: "Import Your Music 📱",
            description: "Tap the 'Import' button to add your own audio files. Supports MP3, WAV, and other common formats.",
            imageName: "square.and.arrow.down"
        ),
        TutorialStep(
            title: "Booklet Generation 📄",
            description: "Create professional service booklets with photos, readings, and service details. Export as PDF for printing.",
            imageName: "doc.text"
        ),
        TutorialStep(
            title: "You're All Set! ✨",
            description: "You're ready to create meaningful funeral services with LuxVia. Tap 'Start Exploring' to begin your journey.",
            imageName: "checkmark.circle.fill",
            isLastStep: true
        )
    ]
    
    private var currentStep = 0
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backgroundImageView = UIImageView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let imageView = UIImageView()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let stepIndicator = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundAndBlur()
        setupUI()
        showStep(index: currentStep)
        
        // Add subtle entrance animation
        view.alpha = 0
        UIView.animate(withDuration: 0.8, delay: 0.2) {
            self.view.alpha = 1
        }
    }
    
    private func setupBackgroundAndBlur() {
        // Create a gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.9).cgColor,
            UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 0.9).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add blur effect
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupUI() {
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Skip button
        skipButton.setTitle("Skip Tour", for: .normal)
        skipButton.setTitleColor(.lightGray, for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(skipButton)
        
        // Step indicator
        stepIndicator.textColor = .lightGray
        stepIndicator.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        stepIndicator.textAlignment = .center
        stepIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepIndicator)
        
        // Progress bar
        progressView.progressTintColor = UIColor(named: "CreamAccent") ?? .systemYellow
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressView)
        
        // Image view
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(named: "CreamAccent") ?? .systemYellow
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // Title label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Description label
        descriptionLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)

        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.backgroundColor = UIColor(named: "CreamAccent") ?? .systemYellow
        nextButton.layer.cornerRadius = 25
        nextButton.layer.shadowColor = UIColor.black.cgColor
        nextButton.layer.shadowOpacity = 0.3
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        nextButton.layer.shadowRadius = 8
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        contentView.addSubview(nextButton)
        
        // Add button press animation
        nextButton.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        nextButton.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside])

        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Skip button
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Step indicator
            stepIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            stepIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: stepIndicator.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Image view
            imageView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 40),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            // Description label
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            // Next button
            nextButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 50),
            nextButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 200),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
        ])
    }
    
    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.nextButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased() {
        UIView.animate(withDuration: 0.1) {
            self.nextButton.transform = .identity
        }
    }

    private func showStep(index: Int) {
        let step = steps[index]
        
        // Animate content transition
        UIView.transition(with: contentView, duration: 0.4, options: .transitionCrossDissolve) {
            self.titleLabel.text = step.title
            self.descriptionLabel.text = step.description
            
            if let imageName = step.imageName {
                self.imageView.image = UIImage(systemName: imageName)
            } else {
                self.imageView.image = nil
            }
            
            self.stepIndicator.text = "\(index + 1) of \(self.steps.count)"
            self.progressView.setProgress(Float(index + 1) / Float(self.steps.count), animated: true)
            
            if step.isLastStep {
                self.nextButton.setTitle("Start Exploring", for: .normal)
                self.nextButton.backgroundColor = UIColor.systemGreen
            } else {
                self.nextButton.setTitle("Next", for: .normal)
                self.nextButton.backgroundColor = UIColor(named: "CreamAccent") ?? .systemYellow
            }
        }
        
        // Add subtle bounce animation to the image
        if imageView.image != nil {
            imageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.6, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
                self.imageView.transform = .identity
            }
        }
    }

    @objc private func nextTapped() {
        if currentStep < steps.count - 1 {
            currentStep += 1
            showStep(index: currentStep)
        } else {
            finishTutorial()
        }
    }
    
    @objc private func skipTapped() {
        let alert = UIAlertController(
            title: "Skip Tutorial?",
            message: "You can always access the app tour later from the main menu.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue Tour", style: .cancel))
        alert.addAction(UIAlertAction(title: "Skip", style: .destructive) { _ in
            self.finishTutorial()
        })
        
        present(alert, animated: true)
    }
    
    private func finishTutorial() {
        // Add completion animation
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            NotificationCenter.default.post(name: .didFinishFirstLaunchTutorial, object: nil)
            self.dismiss(animated: false) {
                // Show quick start guide after main tutorial
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootViewController = window.rootViewController {
                        
                        // Find the topmost presented view controller
                        var topVC = rootViewController
                        while let presented = topVC.presentedViewController {
                            topVC = presented
                        }
                        
                        if QuickStartGuide.shared.shouldShowQuickStart {
                            topVC.showQuickStartGuide()
                        }
                    }
                }
            }
        }
    }
}

// Notification extension for tutorial completion
extension Notification.Name {
    static let didFinishFirstLaunchTutorial = Notification.Name("didFinishFirstLaunchTutorial")
}
