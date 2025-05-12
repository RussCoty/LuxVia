// MusicTabViewController.swift
// FuneralMusic

import UIKit

class MusicTabViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let exploreVC = LibraryViewController()
        exploreVC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "music.note.list"), tag: 0)

        let playlistVC = PlaylistViewController()
        playlistVC.tabBarItem = UITabBarItem(title: "Playlist", image: UIImage(systemName: "music.note"), tag: 1)

        viewControllers = [exploreVC, playlistVC]
    }
}
