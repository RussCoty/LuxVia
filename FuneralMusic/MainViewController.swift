import UIKit
import Foundation

class MainViewController: UIViewController {
    let segmentedControl = UISegmentedControl(items: ["Import", "Library", "Playlist"])
    private let containerView = UIView()

    // 🔒 Full Player (commented out)
    // private let playerControls = PlayerControlsView()

    let libraryVC = MusicViewController()
    let playlistVC = ServiceViewController()

    private var currentTrackIndex = 0
    private var progressTimer: Timer?

    // ✅ Mini Player
    let miniPlayerVC = MiniPlayerContainerViewController()
    private var miniPlayerBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music"

        setupUI()
        setupLogoutButton()
        // setupPlayerCallbacks() ❌ Full player off
        showLibrary()
        setupMiniPlayer()
    }

    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // 🔒 Full Player UI Setup (commented)
        // playerControls.translatesAutoresizingMaskIntoConstraints = false
        // view.addSubview(playerControls)
        // PlayerControlsView.shared = playerControls
        // playerControls.setFadeButtonTitle("Fade Out")

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            // ⛔ no playerControls.topAnchor anymore
        ])

        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
    }

    private func setupMiniPlayer() {
        addChild(miniPlayerVC)
        view.addSubview(miniPlayerVC.view)
        miniPlayerVC.didMove(toParent: self)

        miniPlayerVC.view.translatesAutoresizingMaskIntoConstraints = false
        miniPlayerVC.view.backgroundColor = .systemGray5

        miniPlayerBottomConstraint = miniPlayerVC.view.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: 0
        )

        NSLayoutConstraint.activate([
            miniPlayerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerBottomConstraint,
            miniPlayerVC.view.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    func showMiniPlayer() {
        print("👀 Showing Mini Player")
        miniPlayerBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    func hideMiniPlayer() {
        miniPlayerBottomConstraint.constant = 64
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func setupLogoutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            SessionManager.logout()
        })
        present(alert, animated: true)
    }

    // MARK: - Tab Switching

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: AudioImportManager.presentImportPicker(from: self)
        case 1: showLibrary()
        case 2: showPlaylist()
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

    private func showPlaylist() {
        swapChild(to: playlistVC)
    }

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

    // 🔒 Full Player Callbacks (commented)

    /*
    private func setupPlayerCallbacks() {
        playerControls.onPlayPause = { [weak self] in
            guard let self = self else { return }
            let audio = AudioPlayerManager.shared

            if audio.isPlaying {
                audio.pause()
                self.playerControls.updatePlayButton(isPlaying: false)
                self.playerControls.setFadeButtonTitle("Fade In")
                self.progressTimer?.invalidate()
            } else {
                if audio.isTrackCued {
                    audio.playCuedTrack()
                } else {
                    audio.resume()
                }
                self.playerControls.updatePlayButton(isPlaying: true)
                self.playerControls.setFadeButtonTitle("Fade Out")
                self.startProgressTimer()
            }
        }

        playerControls.onNext = { [weak self] in
            guard let self = self else { return }
            if AudioPlayerManager.shared.currentSource == .playlist {
                SharedPlaylistManager.shared.playNext()
            } else {
                self.advanceToNextTrack()
            }
        }

        playerControls.onVolumeChange = { value in
            AudioPlayerManager.shared.volume = value
        }

        playerControls.onScrubProgress = { [weak self] value in
            AudioPlayerManager.shared.seek(to: TimeInterval(value))
            self?.updateTimeLabel()
        }

        playerControls.onFadeOut = { [weak self] in
            self?.fadeOutMusic()
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let audio = AudioPlayerManager.shared
            if audio.isPlaying {
                self.playerControls.updateProgress(current: Float(audio.currentTime))
                self.playerControls.setMaxProgress(Float(audio.duration))
                self.updateTimeLabel()
            }
        }
    }

    private func updateTimeLabel() {
        let current = Int(AudioPlayerManager.shared.currentTime)
        let duration = Int(AudioPlayerManager.shared.duration)
        playerControls.updateTimeLabel(current: current, duration: duration)
    }

    private func advanceToNextTrack() {
        currentTrackIndex += 1
        if currentTrackIndex < SharedPlaylistManager.shared.playlist.count {
            let nextTrack = SharedPlaylistManager.shared.playlist[currentTrackIndex]
            play(trackNamed: nextTrack.fileName)
        } else {
            AudioPlayerManager.shared.stop()
            playerControls.updatePlayButton(isPlaying: false)
            playerControls.nowPlayingText("Now Playing: —")
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

    private func fadeOutMusic() {
        let audio = AudioPlayerManager.shared
        guard let player = audio.player else { return }

        if audio.isPlaying {
            let totalSteps = Int(7.0 / 0.01)
            let decrement = audio.volume / Float(totalSteps)

            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                if player.volume > decrement {
                    player.volume -= decrement
                } else {
                    timer.invalidate()
                    player.pause()
                    player.volume = audio.volume
                    self.playerControls.updatePlayButton(isPlaying: false)
                    self.playerControls.setFadeButtonTitle("Fade In")
                    self.playerControls.nowPlayingText("Paused after fade")
                }
            }
        } else {
            player.volume = 0
            player.play()
            self.playerControls.updatePlayButton(isPlaying: true)
            self.playerControls.setFadeButtonTitle("Fade Out")

            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                if player.volume < audio.volume - 0.01 {
                    player.volume += 0.01
                } else {
                    player.volume = audio.volume
                    timer.invalidate()
                }
            }
        }
    }
    */
}
