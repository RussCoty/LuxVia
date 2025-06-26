import UIKit

class MiniPlayerContainerViewController: UIViewController {

    private let playerView = PlayerControlsView()
    private var progressTimer: Timer?
    private var currentSong: SongEntry?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupPlayer()
        setupCallbacks()
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
    }

    func configure(with song: SongEntry) {
        currentSong = song
        PlayerControlsView.shared = playerView
        AudioPlayerManager.shared.cueTrack(song, source: .library)

        let cueText = "🎧 Cued: \(song.title)"
        print(cueText)
        playerView.nowPlayingText(cueText)

        playerView.updatePlayButton(isPlaying: false)
        playerView.setMaxProgress(Float(AudioPlayerManager.shared.duration))
        playerView.setVolumeSlider(value: AudioPlayerManager.shared.volume)
        startProgressTimer()
    }

    private func setupCallbacks() {
        playerView.onPlayPause = { [weak self] in
            guard let self = self else { return }
            let audio = AudioPlayerManager.shared

            if audio.isPlaying {
                audio.pause()
                self.playerView.updatePlayButton(isPlaying: false)
                self.playerView.setFadeButtonTitle("Fade In")
                self.stopProgressTimer()
            } else {
                if audio.isTrackCued {
                    audio.playCuedTrack()
                } else {
                    audio.resume()
                }

                let title = self.currentSong?.title ?? "—"
                self.playerView.nowPlayingText("Now Playing: \(title)")
                self.playerView.updatePlayButton(isPlaying: true)
                self.playerView.setFadeButtonTitle("Fade Out")
                self.startProgressTimer()
            }
        }

        playerView.onNext = {
            if AudioPlayerManager.shared.currentSource == .playlist {
                SharedPlaylistManager.shared.playNext()
            }
        }

        playerView.onVolumeChange = { value in
            AudioPlayerManager.shared.volume = value
        }

        playerView.onScrubProgress = { [weak self] value in
            AudioPlayerManager.shared.seek(to: TimeInterval(value))
            self?.updateTimeLabel()
        }

        playerView.onFadeOut = { [weak self] in
            self?.fadeOutMusic()
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let audio = AudioPlayerManager.shared
            if audio.isPlaying {
                self.playerView.updateProgress(current: Float(audio.currentTime))
                self.playerView.setMaxProgress(Float(audio.duration))
                self.updateTimeLabel()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateTimeLabel() {
        let current = Int(AudioPlayerManager.shared.currentTime)
        let duration = Int(AudioPlayerManager.shared.duration)
        playerView.updateTimeLabel(current: current, duration: duration)
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
                    self.playerView.updatePlayButton(isPlaying: false)
                    self.playerView.setFadeButtonTitle("Fade In")
                    self.playerView.nowPlayingText("Paused after fade")
                }
            }
        } else {
            player.volume = 0
            player.play()
            self.playerView.updatePlayButton(isPlaying: true)
            self.playerView.setFadeButtonTitle("Fade Out")

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
