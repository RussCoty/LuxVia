import UIKit

class MiniPlayerContainerViewController: UIViewController {

    private let playerView = PlayerControlsView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        setupPlayer()
    }

    private func setupPlayer() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        PlayerControlsView.shared = playerView // ✅ set singleton reference
    }

    func configure(with song: SongEntry) {
        PlayerControlsView.shared = playerView // ✅ redundant but safe
        playerView.nowPlayingText("Now Playing: \(song.title.replacingOccurrences(of: "_", with: " ").capitalized)")
        playerView.updatePlayButton(isPlaying: false)
        playerView.setMaxProgress(Float(AudioPlayerManager.shared.duration))

        AudioPlayerManager.shared.cueTrack(song, source: .library)
    }
}
