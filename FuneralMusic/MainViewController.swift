import UIKit

class MainViewController: UIViewController {

    private var progressTimer: Timer?

    private let containerView = UIView()
    private let playerControls = PlayerControlsView()
    private lazy var libraryVC = LibraryViewController()
    private lazy var playlistVC = PlaylistViewController()
    private var currentTrackIndex = 0

    private let statusLabel = UILabel() // ✅ Login status

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music"

        setupUI()
        setupPlayerCallbacks()
        showLibrary()

        setupStatusLabel()
        updateLoginStatusLabel()
    }

    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        playerControls.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerView)
        view.addSubview(playerControls)

        PlayerControlsView.shared = playerControls
        playerControls.setFadeButtonTitle("Fade Out")

        NSLayoutConstraint.activate([
            playerControls.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerControls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerControls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: playerControls.topAnchor)
        ])

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
            let audio = AudioPlayerManager.shared

            if audio.isPlaying {
                audio.pause()
                self.playerControls.updatePlayButton(isPlaying: false)
                self.playerControls.setFadeButtonTitle("Fade In")
                self.progressTimer?.invalidate()
                return
            }

            if audio.isPaused {
                if audio.isTrackCued {
                    audio.playCuedTrack()
                } else {
                    audio.resume()
                }
                self.playerControls.updatePlayButton(isPlaying: true)
                self.playerControls.setFadeButtonTitle("Fade Out")
                self.startProgressTimer()
                return
            }

            if audio.isStopped && audio.isTrackCued {
                audio.playCuedTrack()
                self.playerControls.updatePlayButton(isPlaying: true)
                self.playerControls.setFadeButtonTitle("Fade Out")
                self.startProgressTimer()
            }
        }

        playerControls.onNext = { [weak self] in
            self?.advanceToNextTrack()
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

            let player = AudioPlayerManager.shared
            if player.isPlaying {
                let currentTime = Float(player.currentTime)
                let duration = Float(player.duration)
                self.playerControls.updateProgress(current: currentTime)
                self.playerControls.setMaxProgress(duration)
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

    private func fadeOutMusic() {
        let audio = AudioPlayerManager.shared

        if audio.isPlaying {
            guard let player = audio.player else { return }

            let fadeStep: Float = 0.01
            let fadeDuration: TimeInterval = 1.5
            let interval: TimeInterval = 0.01
            let totalSteps = Int(fadeDuration / interval)
            let volumeDecrement = audio.volume / Float(totalSteps)

            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if player.volume > volumeDecrement {
                    player.volume -= volumeDecrement
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
            guard let player = audio.player else { return }

            player.volume = 0
            player.play()
            self.playerControls.updatePlayButton(isPlaying: true)
            self.playerControls.setFadeButtonTitle("Fade Out")

            let fadeTarget: Float = audio.volume
            let fadeStep: Float = 0.01
            let interval: TimeInterval = 0.01

            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if player.volume < fadeTarget - fadeStep {
                    player.volume += fadeStep
                } else {
                    player.volume = fadeTarget
                    timer.invalidate()
                }
            }
        }
    }

    // MARK: - Login Status Label

    private func setupStatusLabel() {
        statusLabel.text = "Guest"
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = .systemGray
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alpha = 0.9

        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            statusLabel.heightAnchor.constraint(equalToConstant: 26),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    func updateLoginStatusLabel() {
        let isMember = UserDefaults.standard.bool(forKey: "isMember")
        statusLabel.text = isMember ? "Member" : "Guest"
        statusLabel.backgroundColor = isMember ? .systemGreen : .systemGray
    }
}
