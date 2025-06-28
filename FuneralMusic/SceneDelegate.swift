//
//  SceneDelegate.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//

import UIKit
import SafariServices

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

        // ✅ Apply global tab bar appearance
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowImage = nil
            appearance.shadowColor = nil

            // ✅ Fix: Set tab item title font & color
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
        self.window = window

        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")

        if isLoggedIn {
            showMainApp()
        } else {
            let loginVC = NativeLoginViewController()
            window.rootViewController = UINavigationController(rootViewController: loginVC)
            window.makeKeyAndVisible()
        }
    }

    func showMainApp() {
        let tabBarController = UITabBarController()

        // Words Tab
        let wordsNav = UINavigationController(rootViewController: WordsListViewController())
        wordsNav.tabBarItem = UITabBarItem(title: "Words", image: nil, tag: 0)

        // Music Tab
        let musicTab = UINavigationController(rootViewController: MainViewController())
        musicTab.tabBarItem = UITabBarItem(title: "Music", image: nil, tag: 1)

        // Service Tab
        let serviceNav = UINavigationController(rootViewController: ServiceViewController())
        serviceNav.tabBarItem = UITabBarItem(title: "Service", image: nil, tag: 2)

        tabBarController.viewControllers = [wordsNav, musicTab, serviceNav]

        // Bold font for tab bar items
        let boldFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        UITabBarItem.appearance().setTitleTextAttributes([.font: boldFont], for: .normal)

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        showGDPRNoticeIfNeeded()
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

    // App Lifecycle
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
