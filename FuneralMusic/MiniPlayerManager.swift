import UIKit



final class MiniPlayerManager {

    static let shared = MiniPlayerManager()

    private var miniPlayerVC: MiniPlayerContainerViewController?
    private var hostView: UIView?
    private var bottomConstraint: NSLayoutConstraint?

    var playerView: PlayerControlsView?

    private init() {}

    func attach(to host: UIViewController) {
        let miniPlayer = MiniPlayerContainerViewController()
        host.addChild(miniPlayer)
        host.view.addSubview(miniPlayer.view)
        miniPlayer.didMove(toParent: host)

        miniPlayer.view.translatesAutoresizingMaskIntoConstraints = false
        let constraint = miniPlayer.view.bottomAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            miniPlayer.view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            miniPlayer.view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            constraint,
            miniPlayer.view.heightAnchor.constraint(equalToConstant: 250)
        ])

        self.miniPlayerVC = miniPlayer
        self.hostView = host.view
        self.bottomConstraint = constraint
    }

    func show(with song: SongEntry) {
        guard let miniPlayerVC = miniPlayerVC,
              let hostView = hostView,
              let bottomConstraint = bottomConstraint else { return }

        miniPlayerVC.configure(with: song)
        bottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            hostView.layoutIfNeeded()
        }
    }

    func hide() {
        guard let hostView = hostView,
              let bottomConstraint = bottomConstraint else { return }

        bottomConstraint.constant = 80
        UIView.animate(withDuration: 0.3) {
            hostView.layoutIfNeeded()
        }
    }

    // 🔵 Show "Now Playing"
    func updateNowPlayingTrack(_ title: String) {
        playerView?.updatePlayingTrackText(title)
    }

    // 🟢 Show "Cued"
    func updateCuedTrackText(_ title: String) {
        playerView?.updateCuedTrackText(title)
    }

    // 🔄 Clear/reset label
    func clearTrackText() {
        playerView?.clearTrackText()
    }
    
    
}
