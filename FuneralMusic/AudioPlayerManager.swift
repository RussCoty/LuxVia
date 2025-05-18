import Foundation
import AVFoundation

class AudioPlayerManager {
    static let shared = AudioPlayerManager()
    private init() {}

    var player: AVAudioPlayer?
    private var playbackLimitTimer: Timer?
    private var fadeTimer: Timer?

    enum AudioSource {
        case none
        case library
        case playlist
    }

    var isPaused: Bool {
        return player?.isPlaying == false && player != nil
    }

    var isStopped: Bool {
        return player == nil
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

            maybeStartPlaybackLimiter()
        } catch {
            print("❌ Error playing audio: \(error)")
        }
    }

    func pause() {
        player?.pause()
        playbackLimitTimer?.invalidate()
    }

    func resume() {
        player?.play()
        maybeStartPlaybackLimiter()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTrackName = nil
        cuedTrackURL = nil
        cuedTrackName = nil
        playbackLimitTimer?.invalidate()
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
    }

    // MARK: - Cue a Track Without Interrupting Playback

    func cueTrack(named name: String, source: AudioSource) {
        guard let url = findMP3(named: name) else {
            print("❌ Could not find track to cue: \(name)")
            return
        }

        cuedTrackName = name
        cuedTrackURL = url
        cuedSource = source

        print("🎵 Cued track: \(name)")
        PlayerControlsView.shared?.nowPlayingText("Ready: \(name.replacingOccurrences(of: "_", with: " ").capitalized)")
    }

    // MARK: - Search Audio Directory Recursively

    private func findMP3(named name: String) -> URL? {
        let fileManager = FileManager.default

        // 1. Search imported documents folder first
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let importedURL = docsURL.appendingPathComponent("audio/imported/\(name).mp3")
            if fileManager.fileExists(atPath: importedURL.path) {
                return importedURL
            }
        }

        // 2. Fallback to bundle search
        if let audioFolder = Bundle.main.resourceURL?.appendingPathComponent("Audio") {
            if let enumerator = fileManager.enumerator(at: audioFolder, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "mp3",
                       fileURL.deletingPathExtension().lastPathComponent == name {
                        return fileURL
                    }
                }
            }
        }

        return nil
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
            PlayerControlsView.shared?.nowPlayingText("Now Playing: \(displayName)")
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

    // MARK: - Fade Out Current Track

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
                player.volume = self.volume
                completion()
            }
        }
    }

    // MARK: - 20 Second Limiter for Non-Members

    private func maybeStartPlaybackLimiter() {
        playbackLimitTimer?.invalidate()

        let isMember = UserDefaults.standard.bool(forKey: "isMember")
        if !isMember {
            playbackLimitTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.isPlaying {
                    self.startFadeOut {
                        self.stop()
                        PlayerControlsView.shared?.nowPlayingText("🔒 Limited to 20 seconds")
                        PlayerControlsView.shared?.updatePlayButton(isPlaying: false)
                    }
                }
            }
        }
    }
}
