import UIKit

class TutorialManager {
    static let shared = TutorialManager()
    
    private init() {
        setupShakeToShowTutorial()
    }
    
    /// Present the app tour from any view controller
    func presentAppTour(from viewController: UIViewController) {
        let tutorial = FirstLaunchTutorialViewController()
        tutorial.modalPresentationStyle = .overFullScreen
        tutorial.modalTransitionStyle = .crossDissolve
        viewController.present(tutorial, animated: true)
    }
    
    /// Check if user has completed the tutorial
    var hasCompletedTutorial: Bool {
        return UserDefaults.standard.bool(forKey: "hasSeenAppTour")
    }
    
    /// Mark tutorial as completed
    func markTutorialCompleted() {
        UserDefaults.standard.set(true, forKey: "hasSeenAppTour")
    }
    
    /// Reset tutorial state (for testing or re-onboarding)
    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: "hasSeenAppTour")
    }
    
    /// Show tutorial options menu
    func showTutorialMenu(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Tutorial & Help",
            message: "Choose a tutorial or help option",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "🎵 Complete App Tour", style: .default) { _ in
            self.presentAppTour(from: viewController)
        })
        
        if let musicVC = findViewController(ofType: MusicViewController.self, in: viewController) {
            alert.addAction(UIAlertAction(title: "🎼 Music Library Tour", style: .default) { _ in
                musicVC.startContextualTour(steps: musicVC.createMusicTourSteps())
            })
        }
        
        if let serviceVC = findViewController(ofType: ServiceViewController.self, in: viewController) {
            alert.addAction(UIAlertAction(title: "📋 Service Planning Tour", style: .default) { _ in
                serviceVC.startContextualTour(steps: serviceVC.createServiceTourSteps())
            })
        }
        
        alert.addAction(UIAlertAction(title: "🔄 Reset All Tutorials", style: .destructive) { _ in
            self.resetTutorial()
            let resetAlert = UIAlertController(
                title: "Tutorials Reset",
                message: "All tutorial progress has been reset. You'll see the welcome tour on next app launch.",
                preferredStyle: .alert
            )
            resetAlert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(resetAlert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(alert, animated: true)
    }
    
    /// Setup shake gesture to show tutorial menu (for advanced users)
    private func setupShakeToShowTutorial() {
        // This will be used by extending UIWindow
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceShaken),
            name: .deviceShaken,
            object: nil
        )
    }
    
    @objc private func deviceShaken() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        // Find the topmost presented view controller
        var topVC = rootViewController
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        // Don't show tutorial menu if already in tutorial
        if topVC is FirstLaunchTutorialViewController {
            return
        }
        
        showTutorialMenu(from: topVC)
    }
    
    private func findViewController<T: UIViewController>(ofType type: T.Type, in viewController: UIViewController) -> T? {
        if let target = viewController as? T {
            return target
        }
        
        // Check in tab bar controller
        if let tabBarController = viewController as? UITabBarController {
            for childVC in tabBarController.viewControllers ?? [] {
                if let found = findViewController(ofType: type, in: childVC) {
                    return found
                }
            }
        }
        
        // Check in navigation controller
        if let navController = viewController as? UINavigationController {
            for childVC in navController.viewControllers {
                if let found = findViewController(ofType: type, in: childVC) {
                    return found
                }
            }
        }
        
        // Check child view controllers
        for childVC in viewController.children {
            if let found = findViewController(ofType: type, in: childVC) {
                return found
            }
        }
        
        return nil
    }
}

// MARK: - Extensions

extension UIViewController {
    /// Convenience method to present app tour
    func presentAppTour() {
        TutorialManager.shared.presentAppTour(from: self)
    }
    
    /// Show tutorial menu with all available options
    func showTutorialMenu() {
        TutorialManager.shared.showTutorialMenu(from: self)
    }
}

// Notification for device shake
extension Notification.Name {
    static let deviceShaken = Notification.Name("deviceShaken")
}

// Custom UIWindow to detect shake gestures
class ShakeDetectingWindow: UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceShaken, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}