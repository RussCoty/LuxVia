//
//  SceneDelegate.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//
import UIKit

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



import UIKit
import SafariServices

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

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

        // About tab (WebView)
        let aboutVC = ViewController()
        aboutVC.tabBarItem = UITabBarItem(title: "Words", image: nil, tag: 0)

        // Music tab (Navigation Controller)
        let musicTab = UINavigationController(rootViewController: MainViewController())
        musicTab.tabBarItem = UITabBarItem(title: "Music", image: nil, tag: 1)

        // Order of Service tab
        let orderVC = OrderOfServiceViewController()
        orderVC.tabBarItem = UITabBarItem(title: "Booklet", image: nil, tag: 2)

        tabBarController.viewControllers = [aboutVC, musicTab, orderVC]

        let biggerFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        UITabBarItem.appearance().setTitleTextAttributes([.font: biggerFont], for: .normal)

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

    // Other lifecycle methods
    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}
