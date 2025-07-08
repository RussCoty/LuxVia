import UIKit



final class MiniPlayerManager {

    static let shared = MiniPlayerManager()

    private var miniPlayerVC: MiniPlayerContainerViewController?
    private var hostView: UIView?
    private var bottomConstraint: NSLayoutConstraint?

    var playerView: PlayerControlsView?

    private init() {
        
        AudioPlayerManager.shared.onStateChanged = { [weak self] in
            self?.syncPlayerUI()
        }

    }

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
    func syncPlayerUI() {
        guard let playerView = playerView else { return }
        let audio = AudioPlayerManager.shared

        // 🎵 Now Playing
        if let title = audio.currentTrackName {
            playerView.updatePlayingTrackText(title)
        } else {
            playerView.updatePlayingTrackText("—")
        }

        // 🎧 Cued Track
        if let cued = audio.cuedTrack?.title, audio.isTrackCued {
            playerView.updateCuedTrackText(cued)
        } else {
            playerView.updateCuedTrackText("")
        }

        // ▶️ Play State
        playerView.updatePlayButton(isPlaying: audio.isPlaying)

        // 🌊 Fade Button & Icon
        let isFadingOut = !audio.isPlaying
        playerView.setFadeButtonTitle(isFadingOut ? "Fade In" : "Fade Out")
        playerView.updateFadeIcon(isFadingOut: isFadingOut)

        // 🎚️ Sliders
        playerView.setVolumeSlider(value: audio.volume)
        playerView.setMaxProgress(Float(audio.duration))
        playerView.updateProgress(current: Float(audio.currentTime))
        playerView.updateTimeLabel(
            current: Int(audio.currentTime),
            duration: Int(audio.duration)
        )
    }
    func setupCallbacks(for playerView: PlayerControlsView) {
        self.playerView = playerView  // ✅ Make this the global, synced view
        let audio = AudioPlayerManager.shared


        playerView.onPlayCued = {
            guard audio.isTrackCued else { return }

            audio.playCuedTrack()
            let title = audio.currentTrackName ?? "—"
            playerView.updatePlayingTrackText(title)
            playerView.clearCuedText()
            playerView.updatePlayButton(isPlaying: true)
            playerView.setFadeButtonTitle("Fade Out")
            playerView.updateFadeIcon(isFadingOut: false)
        }

        playerView.onPlayPause = {
            let title = audio.currentTrackName ?? "—"

            if audio.isPlaying {
                audio.pause()
                playerView.updatePlayButton(isPlaying: false)
                playerView.setFadeButtonTitle("Fade In")
                playerView.updateFadeIcon(isFadingOut: true)
                playerView.updatePlayingTrackText("Paused: \(title)")
                return
            }

            if audio.hasPlayableTrack {
                audio.resume()
                if audio.isPlaying {
                    playerView.updatePlayingTrackText(title)
                }
                playerView.updatePlayButton(isPlaying: true)
                playerView.setFadeButtonTitle("Fade Out")
                playerView.updateFadeIcon(isFadingOut: false)
                return
            }

            if audio.hasFinishedPlaying && audio.isTrackCued {
                audio.playCuedTrack()
                playerView.clearCuedText()
                playerView.updatePlayingTrackText(title)
                playerView.updatePlayButton(isPlaying: true)
                playerView.setFadeButtonTitle("Fade Out")
                playerView.updateFadeIcon(isFadingOut: false)
                return
            }

            if audio.isTrackCued {
                audio.playCuedTrack()
                playerView.clearCuedText()
                playerView.updatePlayingTrackText("Now Playing: \(audio.currentTrackName ?? title)")
                playerView.updatePlayButton(isPlaying: true)
                playerView.setFadeButtonTitle("Fade Out")
                playerView.updateFadeIcon(isFadingOut: false)
            }
        }

        playerView.onVolumeChange = { value in
            audio.volume = value
        }

        playerView.onScrubProgress = { value in
            audio.seek(to: TimeInterval(value))
        }

        playerView.onFadeOut = {
            MiniPlayerManager.shared.fadeOutMusic()
        }

        audio.onPlaybackEnded = {
            playerView.updatePlayButton(isPlaying: false)
            playerView.updatePlayingTrackText("Finished: \(audio.currentTrackName ?? "—")")
        }
    }

     func fadeOutMusic() {
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
                    self.playerView?.updatePlayButton(isPlaying: false)
                    self.playerView?.setFadeButtonTitle("Fade In")
                    self.playerView?.updateFadeIcon(isFadingOut: true)
                    self.playerView?.updatePlayingTrackText("Paused after fade")
                }
            }
        } else {
            player.volume = 0
            player.play()

            let title = audio.currentTrackName ?? "—"
            self.playerView?.updatePlayingTrackText(title)
            self.playerView?.updatePlayButton(isPlaying: true)
            self.playerView?.setFadeButtonTitle("Fade Out")
            self.playerView?.updateFadeIcon(isFadingOut: false)



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
}
