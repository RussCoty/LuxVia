import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabs()
        setupMiniPlayer()

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let normalAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.gray]
        let selectedAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func setupTabs() {
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .selected)

        let wordsVC = UINavigationController(rootViewController: WordsListViewController())
        wordsVC.tabBarItem = UITabBarItem(title: "Words", image: UIImage(systemName: "book"), tag: 0)

        let musicVC = UINavigationController(rootViewController: MusicViewController())
        musicVC.tabBarItem = UITabBarItem(title: "Music", image: UIImage(systemName: "music.note.list"), tag: 1)

        let serviceVC = UINavigationController(rootViewController: ServiceViewController())
        serviceVC.tabBarItem = UITabBarItem(title: "Service", image: UIImage(systemName: "music.note"), tag: 2)

        viewControllers = [wordsVC, musicVC, serviceVC]
        selectedIndex = 1
    }

    private func setupMiniPlayer() {
        MiniPlayerManager.shared.attach(to: self)
        MiniPlayerManager.shared.show()
    }

    // 👇 Ensures MiniPlayer is hidden on Words tab
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let shouldShowMiniPlayer = selectedIndex == 1 || selectedIndex == 2 // Music or Service
        MiniPlayerManager.shared.setVisible(shouldShowMiniPlayer)
    }
}
