import Foundation
import AVFoundation

class AudioPlayerManager {
    static let shared = AudioPlayerManager()
    private init() {}

    var player: AVAudioPlayer?

    enum AudioSource {
        case none
        case library
        case playlist
    }

    var currentSource: AudioSource = .none
    var currentTrackName: String?
    var volume: Float = 0.75 {
        didSet {
            player?.volume = volume
        }
    }

    // MARK: - Cueing Support
    var cuedTrackName: String?
    var cuedSource: AudioSource = .none
    private var cuedTrackURL: URL?
    private var fadeTimer: Timer?

    var isTrackCued: Bool {
        return cuedTrackURL != nil
    }

    var currentTime: TimeInterval {
        return player?.currentTime ?? 0
    }

    var duration: TimeInterval {
        return player?.duration ?? 1
    }

    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }

    // MARK: - Load and Play

    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()

            currentTrackName = url.deletingPathExtension().lastPathComponent
            cuedTrackName = nil
            cuedTrackURL = nil
            cuedSource = .none
        } catch {
            print("❌ Error playing audio: \(error)")
        }
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTrackName = nil
        cuedTrackURL = nil
        cuedTrackName = nil
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
    }

    // MARK: - Cue a Track Without Interrupting Playback

    func cueTrack(named name: String, source: AudioSource) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") else {
            print("❌ Could not find track to cue: \(name)")
            return
        }

        cuedTrackName = name
        cuedTrackURL = url
        cuedSource = source

        print("🎵 Cued track: \(name)")
        PlayerControlsView.shared?.nowPlayingText("Ready: \(name.replacingOccurrences(of: "_", with: " ").capitalized)")
    }

    // MARK: - Play the Cued Track

    func playCuedTrack() {
        guard let url = cuedTrackURL else {
            print("⚠️ No track cued")
            return
        }

        let trackName = url.deletingPathExtension().lastPathComponent
        let displayName = trackName.replacingOccurrences(of: "_", with: " ").capitalized

        let playNow = {
            self.play(url: url)
            self.currentSource = self.cuedSource
            PlayerControlsView.shared?.nowPlayingText("Now Playing: \(displayName)") // ✅ Add this line
            PlayerControlsView.shared?.updatePlayButton(isPlaying: true)
        }

        if isPlaying {
            startFadeOut {
                playNow()
            }
        } else {
            playNow()
        }
    }


    // MARK: - Fade Out Helper

    private func startFadeOut(completion: @escaping () -> Void) {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.player else {
                timer.invalidate()
                completion()
                return
            }

            if player.volume > 0.05 {
                player.volume -= 0.05
            } else {
                timer.invalidate()
                player.stop()
                player.volume = self.volume // Restore user volume after fade
                completion()
            }
        }
    }
}

