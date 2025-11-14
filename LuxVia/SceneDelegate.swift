import UIKit
import SafariServices
import WebKit

class SessionManager {
    static func logout() {
        KeychainHelper.standard.delete(service: "jwt", account: "funeralmusic")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isMember")

        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            let loginVC = NativeLoginViewController()
            sceneDelegate.window?.rootViewController = UINavigationController(rootViewController: loginVC)
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        // ✅ Force guest mode on first launch
        let forcedGuestMode = true
        if forcedGuestMode {
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.synchronize()
        }

        // 🔧 Clear WKWebView cookies to avoid auto-login via cookie
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                print("🧹 Cleared WKWebView cookies")
            }
        }

        // ✅ Apply global tab bar appearance
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowImage = nil
            appearance.shadowColor = nil

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.gray
            ]
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = attributes
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.label
            ]

            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        // Note: ShakeDetectingWindow defined in TutorialManager.swift
        // For now, use standard UIWindow - shake detection can be added later
        self.window = window

        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")

        if isLoggedIn {
            showMainApp()
        } else {
            let loginVC = NativeLoginViewController()
            window.rootViewController = UINavigationController(rootViewController: loginVC)
            window.makeKeyAndVisible()
            // Observe tutorial completion and present tutorial if needed
            NotificationCenter.default.addObserver(self, selector: #selector(tutorialFinished), name: .didFinishFirstLaunchTutorial, object: nil)
            presentFirstLaunchTutorialIfNeeded()
        }
    }

    func showMainApp() {
        let tabBarController = MainTabBarController()

        let wordsNav = UINavigationController(rootViewController: WordsListViewController())
        wordsNav.tabBarItem = UITabBarItem(title: "Words", image: nil, tag: 0)

        let musicTab = UINavigationController(rootViewController: MainViewController())
        musicTab.tabBarItem = UITabBarItem(title: "Music", image: nil, tag: 1)

        let serviceNav = UINavigationController(rootViewController: ServiceViewController())
        serviceNav.tabBarItem = UITabBarItem(title: "Service", image: nil, tag: 2)

        tabBarController.viewControllers = [wordsNav, musicTab, serviceNav]
        tabBarController.selectedIndex = 1

        let boldFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        UITabBarItem.appearance().setTitleTextAttributes([.font: boldFont], for: .normal)

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        // Observe tutorial completion and present tutorial if needed
        NotificationCenter.default.addObserver(self, selector: #selector(tutorialFinished), name: .didFinishFirstLaunchTutorial, object: nil)
        presentFirstLaunchTutorialIfNeeded()

        showGDPRNoticeIfNeeded()
    }

    // MARK: - First-launch tutorial

    @objc func tutorialFinished() {
        UserDefaults.standard.set(true, forKey: "hasSeenAppTour")
        NotificationCenter.default.removeObserver(self, name: .didFinishFirstLaunchTutorial, object: nil)
    }

    func presentFirstLaunchTutorialIfNeeded() {
        let hasSeen = UserDefaults.standard.bool(forKey: "hasSeenAppTour")
        guard !hasSeen else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self, let root = self.window?.rootViewController else { return }
            let tutorial = FirstLaunchTutorialViewController()
            tutorial.modalPresentationStyle = .overFullScreen
            root.present(tutorial, animated: true, completion: nil)
        }
    }

    func showGDPRNoticeIfNeeded() {
        let hasSeenNotice = UserDefaults.standard.bool(forKey: "hasSeenGDPRNotice")
        if !hasSeenNotice {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let alert = UIAlertController(
                    title: "Privacy Notice",
                    message: "This app does not collect any personal data. Some website content may use cookies as part of the embedded pages.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    UserDefaults.standard.set(true, forKey: "hasSeenGDPRNotice")
                })
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) {
        LyricsSyncManager.shared.syncLyrics { result in
            switch result {
            case .success(let lyrics):
                print("✅ Synced \(lyrics.count) lyrics.")
            case .failure(let error):
                print("❌ Lyrics sync failed: \(error.localizedDescription)")
            }
        }
    }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }

    func presentLoginScreen() {
        let loginVC = NativeLoginViewController()
        let nav = UINavigationController(rootViewController: loginVC)
        self.window?.rootViewController = nav
        self.window?.makeKeyAndVisible()
    }
}
