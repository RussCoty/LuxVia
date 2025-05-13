import UIKit

class MainViewController: UIViewController {

    private let containerView = UIView()
    private let playerControls = PlayerControlsView()

    private lazy var libraryVC = LibraryViewController()
    private lazy var playlistVC = PlaylistViewController()

    private var currentTrackIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music"

        setupUI()
        setupPlayerCallbacks()
        showLibrary() // default view
    }

    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        playerControls.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerView)
        view.addSubview(playerControls)

        NSLayoutConstraint.activate([
            playerControls.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerControls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerControls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: playerControls.topAnchor)
        ])

        // Segmented Control (Library / Playlist)
        let segmentedControl = UISegmentedControl(items: ["Library", "Playlist"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            showLibrary()
        } else {
            showPlaylist()
        }
    }

    private func showLibrary() {
        swapChild(to: libraryVC)
    }

    private func showPlaylist() {
        swapChild(to: playlistVC)
    }

    private func swapChild(to newVC: UIViewController) {
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        addChild(newVC)
        containerView.addSubview(newVC.view)
        newVC.view.frame = containerView.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newVC.didMove(toParent: self)
    }

    private func setupPlayerCallbacks() {
        playerControls.onPlayPause = { [weak self] in
            guard let self = self else { return }
            if AudioPlayerManager.shared.isPlaying {
                AudioPlayerManager.shared.pause()
                self.playerControls.updatePlayButton(isPlaying: false)
            } else {
                AudioPlayerManager.shared.resume()
                self.playerControls.updatePlayButton(isPlaying: true)
            }
        }

        playerControls.onNext = { [weak self] in
            guard let self = self else { return }
            self.advanceToNextTrack()
        }

        playerControls.onVolumeChange = { value in
            AudioPlayerManager.shared.volume = value
        }

        playerControls.onScrubProgress = { [weak self] value in
            AudioPlayerManager.shared.seek(to: TimeInterval(value))
            self?.updateTimeLabel()
        }

        playerControls.onFadeOut = { [weak self] in
            guard let self = self else { return }
            self.fadeOutMusic()
        }

        playerControls.onPlayPlaylist = { [weak self] in
            guard let self = self else { return }
            guard !SharedPlaylistManager.shared.playlist.isEmpty else { return }
            self.currentTrackIndex = 0
            let track = SharedPlaylistManager.shared.playlist[self.currentTrackIndex]
            self.play(trackNamed: track)
        }
    }

    private func advanceToNextTrack() {
        currentTrackIndex += 1
        if currentTrackIndex < SharedPlaylistManager.shared.playlist.count {
            let nextTrack = SharedPlaylistManager.shared.playlist[currentTrackIndex]
            play(trackNamed: nextTrack)
        } else {
            AudioPlayerManager.shared.stop()
            playerControls.updatePlayButton(isPlaying: false)
            playerControls.nowPlayingText("Now Playing: —")
            playerControls.updateProgress(current: 0)
        }
    }

    private func play(trackNamed name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") else { return }

        AudioPlayerManager.shared.play(url: url)
        playerControls.updatePlayButton(isPlaying: true)
        playerControls.nowPlayingText("Now Playing: \(name.replacingOccurrences(of: "_", with: " ").capitalized)")
        playerControls.setMaxProgress(Float(AudioPlayerManager.shared.duration))

        startProgressTimer()
    }

    private func startProgressTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let player = AudioPlayerManager.shared
            if player.isPlaying {
                self.playerControls.updateProgress(current: Float(player.currentTime))
                self.playerControls.setMaxProgress(Float(player.duration))
                self.updateTimeLabel()
            }
        }
    }

    private func updateTimeLabel() {
        let current = Int(AudioPlayerManager.shared.currentTime)
        let duration = Int(AudioPlayerManager.shared.duration)
        playerControls.updateTimeLabel(current: current, duration: duration)
    }

    private func fadeOutMusic() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard let player = AudioPlayerManager.shared.player else {
                timer.invalidate()
                return
            }

            if player.volume > 0.01 {
                player.volume -= 0.01
            } else {
                AudioPlayerManager.shared.stop()
                self.playerControls.updatePlayButton(isPlaying: false)
                self.playerControls.nowPlayingText("Now Playing: —")
                self.playerControls.updateProgress(current: 0)
                timer.invalidate()
            }
        }
    }
}
