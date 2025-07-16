import UIKit

class MusicTabViewController: UITabBarController {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
}
