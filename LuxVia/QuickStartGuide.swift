import UIKit

class QuickStartGuide {
    static let shared = QuickStartGuide()
    
    private init() {}
    
    /// Show quick start tips for first-time users
    func showQuickStartTips(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "🚀 Quick Start Tips",
            message: "Here are some pro tips to get you started with LuxVia:",
            preferredStyle: .alert
        )
        
        let tipsMessage = """
        💡 Shake your device anywhere in the app to access tutorials and help
        
        🎵 Import your music files to build a personal library
        
        📋 Use the Service tab to plan funeral orders
        
        📖 Browse readings and create custom ones in the Words tab
        
        🎛️ Use mini player controls for smooth audio transitions
        
        📄 Generate professional booklets with service details
        """
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let tipsLabel = UILabel()
        tipsLabel.text = tipsMessage
        tipsLabel.font = UIFont.systemFont(ofSize: 14)
        tipsLabel.numberOfLines = 0
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(tipsLabel)
        
        // Create a container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)
        
        alert.setValue(containerView, forKey: "contentViewController")
        
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: 280),
            containerView.heightAnchor.constraint(equalToConstant: 200),
            
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            tipsLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            tipsLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8),
            tipsLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8),
            tipsLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            tipsLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16)
        ])
        
        alert.addAction(UIAlertAction(title: "Show Tutorial Again", style: .default) { _ in
            TutorialManager.shared.presentAppTour(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Got it!", style: .default) { _ in
            UserDefaults.standard.set(true, forKey: "hasSeenQuickStart")
        })
        
        viewController.present(alert, animated: true)
    }
    
    /// Check if quick start should be shown
    var shouldShowQuickStart: Bool {
        return !UserDefaults.standard.bool(forKey: "hasSeenQuickStart")
    }
    
    /// Show contextual tips based on current screen
    func showContextualTip(for feature: AppFeature, from viewController: UIViewController) {
        let tip = getTip(for: feature)
        
        let alert = UIAlertController(
            title: tip.title,
            message: tip.message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Thanks!", style: .default))
        
        if tip.hasAdvancedHelp {
            alert.addAction(UIAlertAction(title: "Show More Help", style: .default) { _ in
                viewController.showTutorialMenu()
            })
        }
        
        viewController.present(alert, animated: true)
    }
    
    private func getTip(for feature: AppFeature) -> ContextualTip {
        switch feature {
        case .musicImport:
            return ContextualTip(
                title: "🎵 Music Import Tip",
                message: "You can import MP3, WAV, M4A and other audio files. Organize them into folders on your device for easier management!",
                hasAdvancedHelp: true
            )
        case .serviceCreation:
            return ContextualTip(
                title: "📋 Service Planning Tip",
                message: "Drag items to reorder them in edit mode. Add readings and music to create a complete service flow.",
                hasAdvancedHelp: true
            )
        case .bookletGeneration:
            return ContextualTip(
                title: "📄 Booklet Tip",
                message: "Fill in the Details tab first, then generate a PDF booklet with all service information for attendees.",
                hasAdvancedHelp: true
            )
        case .miniPlayer:
            return ContextualTip(
                title: "🎛️ Audio Control Tip",
                message: "Use fade in/out controls for smooth transitions between tracks during the service.",
                hasAdvancedHelp: false
            )
        case .readings:
            return ContextualTip(
                title: "📖 Readings Tip",
                message: "Browse traditional readings or create custom ones. Tap any reading to add it to your service.",
                hasAdvancedHelp: true
            )
        }
    }
}

struct ContextualTip {
    let title: String
    let message: String
    let hasAdvancedHelp: Bool
}

enum AppFeature {
    case musicImport
    case serviceCreation
    case bookletGeneration
    case miniPlayer
    case readings
}

// Extension for easy access
extension UIViewController {
    /// Show quick start guide
    func showQuickStartGuide() {
        QuickStartGuide.shared.showQuickStartTips(from: self)
    }
    
    /// Show contextual tip for a specific feature
    func showContextualTip(for feature: AppFeature) {
        QuickStartGuide.shared.showContextualTip(for: feature, from: self)
    }
}