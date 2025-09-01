//
//  AppDelegate.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//


import LuxVia.Notifications

//extension Notification.Name {
//    static let authStatusChanged = Notification.Name("authStatusChanged")
//}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
        if !hasSeenTutorial {
            let tutorialVC = FirstLaunchTutorialViewController()
            window?.rootViewController = tutorialVC
            NotificationCenter.default.addObserver(self, selector: #selector(showMainUI), name: .didFinishFirstLaunchTutorial, object: nil)
        } else {
            // Existing main UI setup
            AuthManager.shared.login() //debugging here
            print("🧭 updateLoginButton CALLED — logged in =", AuthManager.shared.isLoggedIn)
            // ✅ Load lyrics CSV into memory
            LyricsLibraryManager.shared.loadLyricsFromCSV()
            let ivoryColor = UIColor(named: "IvoryBackground") ?? UIColor(red: 1.0, green: 0.996, blue: 0.949, alpha: 1.0) // Fallback if asset missing
            window?.rootViewController = MainTabBarController() // Replace with your main entry point
        }
        window?.makeKeyAndVisible()
        return true
    }

    @objc private func showMainUI() {
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        // Existing main UI setup
        AuthManager.shared.login() //debugging here
        print("🧭 updateLoginButton CALLED — logged in =", AuthManager.shared.isLoggedIn)
        LyricsLibraryManager.shared.loadLyricsFromCSV()
        let ivoryColor = UIColor(named: "IvoryBackground") ?? UIColor(red: 1.0, green: 0.996, blue: 0.949, alpha: 1.0)
        window?.rootViewController = MainTabBarController() // Replace with your main entry point
    }



    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

