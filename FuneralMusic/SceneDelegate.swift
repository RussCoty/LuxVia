//
//  SceneDelegate.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    
    

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let tabBarController = UITabBarController()

        let webVC = ViewController()
        webVC.tabBarItem = UITabBarItem(title: "About", image: nil, tag: 0)

        let musicVC = LibraryViewController()
        musicVC.tabBarItem = UITabBarItem(title: "Music Library", image: nil, tag: 1)
        
        let orderVC = OrderOfServiceViewController()
        orderVC.tabBarItem = UITabBarItem(title: "Order of Service", image: nil, tag: 2)


        tabBarController.viewControllers = [webVC, musicVC, orderVC]
        window.rootViewController = tabBarController
  // Your custom ViewController
        self.window = window
        window.makeKeyAndVisible()

        
        window.rootViewController = tabBarController
        self.window = window
        window.makeKeyAndVisible()

        showGDPRNoticeIfNeeded()


    }
    
    

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func showGDPRNoticeIfNeeded() {
        let hasSeenNotice = UserDefaults.standard.bool(forKey: "hasSeenGDPRNotice")
        if !hasSeenNotice {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let alert = UIAlertController(title: "Privacy Notice",
                                              message: "This app does not collect any personal data. Some website content may use cookies as part of the embedded pages.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    UserDefaults.standard.set(true, forKey: "hasSeenGDPRNotice")
                }))
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    func showMainApp() {
        let tabBarController = UITabBarController()

        let aboutVC = ViewController()
        aboutVC.tabBarItem = UITabBarItem(title: "About", image: nil, tag: 0)

        let musicVC = LibraryViewController()
        musicVC.tabBarItem = UITabBarItem(title: "Music", image: nil, tag: 1)

        let orderVC = OrderOfServiceViewController()
        orderVC.tabBarItem = UITabBarItem(title: "Order", image: nil, tag: 2)

        tabBarController.viewControllers = [aboutVC, musicVC, orderVC]

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        showGDPRNoticeIfNeeded()
    }

}
