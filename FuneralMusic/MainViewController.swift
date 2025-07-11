import UIKit
import Foundation

class MainViewController: UIViewController {

    let segmentedControl = UISegmentedControl(items: ["Import", "Library"])
    private let containerView = UIView()

    let libraryVC = MusicViewController()
    //let playlistVC = ServiceViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music"
        
        print("🔍 isLoggedIn =", AuthManager.shared.isLoggedIn)
        print("📍 MainViewController loaded")


        setupUI()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLoginButton),
            name: .authStatusChanged,
            object: nil
        )

        showLibrary()

        MiniPlayerManager.shared.attach(to: self) // ✅ Correct usage

    }
    


    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
    }

    private func setupLogoutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AuthManager.shared.isLoggedIn ? "Logout" : "Login",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }

    @objc private func logoutTapped() {
        print("✅ Running MainViewController.logoutTapped")
        let alert = UIAlertController(
            title: AuthManager.shared.isLoggedIn ? "Logout" : "Login",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // FIXED: removed invalid addition of voids
        alert.addAction(UIAlertAction(title: AuthManager.shared.isLoggedIn ? "Logout" : "Login", style: .destructive) { _ in            SessionManager.logout()
        })
        present(alert, animated: true)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: AudioImportManager.presentImportPicker(from: self)
        case 1: showLibrary()
       // case 2: showPlaylist()
        default: break
        }
    }

    @objc func selectSegment(index: Int) {
        segmentedControl.selectedSegmentIndex = index
        segmentChanged(segmentedControl)
    }

    private func showLibrary() {
        swapChild(to: libraryVC)
    }

//    private func showPlaylist() {
//        swapChild(to: playlistVC)
//    }

    private func swapChild(to newVC: UIViewController) {
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        addChild(newVC)
        containerView.addSubview(newVC.view)
        newVC.view.frame = containerView.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newVC.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupLogoutButton()

        if let playerView = libraryVC.playerView {
            MiniPlayerManager.shared.playerView = playerView
            MiniPlayerManager.shared.setupCallbacks(for: playerView)
            MiniPlayerManager.shared.syncPlayerUI()
        } else {
            print("⚠️ Warning: libraryVC.playerView is nil")
        }
    }

    @objc private func updateLoginButton() {
        print("🔄 MainViewController updateLoginButton fired. Logged in =", AuthManager.shared.isLoggedIn)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AuthManager.shared.isLoggedIn ? "Logout" : "Login",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }


}

