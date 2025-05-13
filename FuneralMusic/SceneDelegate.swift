//
//  SceneDelegate.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let tabBarController = UITabBarController()

        // About tab (WebView)
        let webVC = ViewController()
        webVC.tabBarItem = UITabBarItem(title: "About", image: nil, tag: 0)

        // Music tab containing Explore + Playlist
        let musicTab = MusicTabViewController()
        musicTab.tabBarItem = UITabBarItem(title: "Music", image: nil, tag: 1)

        // Order of Service tab
        let orderVC = OrderOfServiceViewController()
        orderVC.tabBarItem = UITabBarItem(title: "Order of Service", image: nil, tag: 2)

        tabBarController.viewControllers = [webVC, musicTab, orderVC]
        window.rootViewController = tabBarController
        self.window = window
        window.makeKeyAndVisible()

        showGDPRNoticeIfNeeded()
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }

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

    func showMainApp() {
        let tabBarController = UITabBarController()

        let aboutVC = ViewController()
        aboutVC.tabBarItem = UITabBarItem(title: "About", image: nil, tag: 0)

        let musicTab = MusicTabViewController()
        musicTab.tabBarItem = UITabBarItem(title: "Music", image: nil, tag: 1)

        let orderVC = OrderOfServiceViewController()
        orderVC.tabBarItem = UITabBarItem(title: "Order of Service", image: nil, tag: 2)

        tabBarController.viewControllers = [aboutVC, musicTab, orderVC]

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        showGDPRNoticeIfNeeded()
    }

}

