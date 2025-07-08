import UIKit

class MiniPlayerContainerViewController: UIViewController {

    let playerView = PlayerControlsView()
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

//        print(cueText)
        //playerView.clearTrackText()
        playerView.updateCuedTrackText(song.title)

        playerView.updatePlayButton(isPlaying: false)
        playerView.setFadeButtonTitle("Fade In")
        playerView.updateFadeIcon(isFadingOut: true)
        playerView.setMaxProgress(Float(AudioPlayerManager.shared.duration))
        playerView.setVolumeSlider(value: AudioPlayerManager.shared.volume)
        startProgressTimer()
    }

    private func setupCallbacks() {
        playerView.onPlayCued = { [weak self] in
            guard let self = self else { return }
            let audio = AudioPlayerManager.shared
            print("--- Play Cued Pressed ---")
            print("isTrackCued: \(audio.isTrackCued)")

            guard audio.isTrackCued else {
                print("→ No cued track to play")
                return
            }

            audio.playCuedTrack()
            let title = audio.currentTrackName ?? self.currentSong?.title ?? "—"
            self.playerView.updatePlayingTrackText(title)
            self.playerView.clearCuedText() // ✅ clear cued label here
            self.playerView.updatePlayButton(isPlaying: true)
            self.playerView.setFadeButtonTitle("Fade Out")
            self.playerView.updateFadeIcon(isFadingOut: false)
            self.startProgressTimer()
        }

        playerView.onPlayPause = { [weak self] in
            guard let self = self else { return }
            let audio = AudioPlayerManager.shared

            print("--- Play/Pause Pressed ---")
            print("isPlaying: \(audio.isPlaying)")
            print("isTrackCued: \(audio.isTrackCued)")
            print("hasFinishedPlaying: \(audio.hasFinishedPlaying)")
            print("hasPlayableTrack: \(audio.hasPlayableTrack)")
            print("currentTrackName: \(audio.currentTrackName ?? "nil")")
            print("cuedTrack: \(audio.cuedTrack?.title ?? "nil")")

            let title = audio.currentTrackName ?? self.currentSong?.title ?? "—"

            if audio.isPlaying {
                print("→ Pause current track")
                audio.pause()
                self.playerView.updatePlayButton(isPlaying: false)
                self.playerView.setFadeButtonTitle("Fade In")
                self.playerView.updateFadeIcon(isFadingOut: true)
                self.playerView.updatePlayingTrackText(title)
                self.stopProgressTimer()
                return
            }

            if audio.hasPlayableTrack {
                print("→ Resume paused track")
                audio.resume()
                if audio.isPlaying {
                    self.playerView.updatePlayingTrackText(title)
                }
                self.playerView.updatePlayButton(isPlaying: true)
                self.playerView.setFadeButtonTitle("Fade Out")
                self.playerView.updateFadeIcon(isFadingOut: false)
                self.startProgressTimer()
                return
            }

            if audio.hasFinishedPlaying && audio.isTrackCued {
                print("→ Finished track, promote and play cue")
                audio.playCuedTrack()
                self.playerView.updatePlayingTrackText("Now Playing: \(audio.currentTrackName ?? title)")
                self.playerView.updatePlayButton(isPlaying: true)
                self.playerView.setFadeButtonTitle("Fade Out")
                self.playerView.updateFadeIcon(isFadingOut: false)
                self.startProgressTimer()
                return
            }

            if audio.isTrackCued {
                print("→ No active track, play cued track")
                audio.playCuedTrack()
                self.playerView.updatePlayingTrackText("Now Playing: \(audio.currentTrackName ?? title)")
                self.playerView.updatePlayButton(isPlaying: true)
                self.playerView.setFadeButtonTitle("Fade Out")
                self.playerView.updateFadeIcon(isFadingOut: false)
                self.startProgressTimer()
                return
            }

            print("→ No action taken")
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
            MiniPlayerManager.shared.fadeOutMusic()
        }
        
        AudioPlayerManager.shared.onPlaybackEnded = {
            self.playerView.updatePlayButton(isPlaying: false)
            self.playerView.updatePlayingTrackText("Finished: \(AudioPlayerManager.shared.currentTrackName ?? "—")")
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


}

extension AudioPlayerManager {
    var hasFinishedPlaying: Bool {
        return !isPlaying && duration > 0 && currentTime >= duration
    }

    var hasPlayableTrack: Bool {
        return currentTrackName != nil && !isPlaying && currentTime < duration
    }
    
 

}
