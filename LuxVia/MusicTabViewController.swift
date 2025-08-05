import UIKit

class MusicTabViewController: UITabBarController, UITabBarControllerDelegate {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let musicVC = storyboard.instantiateViewController(withIdentifier: "MusicViewController") as? MusicViewController,
              let serviceVC = storyboard.instantiateViewController(withIdentifier: "ServiceViewController") as? ServiceViewController else {
            print("❌ Could not load child view controllers from storyboard.")
            return
        }

        musicVC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "music.note.list"), tag: 0)
        serviceVC.tabBarItem = UITabBarItem(title: "Service", image: UIImage(systemName: "music.note"), tag: 1)

        viewControllers = [musicVC, serviceVC]
    }

    // 👇 Prevent re-tap on Service if not at root
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController == selectedViewController {
            if let nav = viewController as? UINavigationController,
               nav.viewControllers.first is ServiceViewController {
                if nav.viewControllers.count > 1 {
                    return false
                }
            }
        }
        return true
    }
}
