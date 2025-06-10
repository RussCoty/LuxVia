// MusicTabViewController.swift
// FuneralMusic

import UIKit

class MusicTabViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let musicVC = MusicViewController()
        musicVC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "music.note.list"), tag: 0)

        let serviceVC = ServiceViewController()
        serviceVC.tabBarItem = UITabBarItem(title: "Service", image: UIImage(systemName: "music.note"), tag: 1)

        viewControllers = [musicVC, serviceVC]
    }
}

