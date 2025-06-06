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
            print("▶️ Playing URL: \(url.lastPathComponent)")
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
        print("⏸ Pause pressed")
        player?.pause()
        playbackLimitTimer?.invalidate()
    }

    func resume() {
        print("▶️ Resume pressed")
        player?.play()
        maybeStartPlaybackLimiter()
    }

    func stop() {
        print("⏹ Stop pressed")
        player?.stop()
        player?.currentTime = 0
        currentTrackName = nil
        cuedTrackURL = nil
        cuedTrackName = nil
        playbackLimitTimer?.invalidate()
    }

    func seek(to time: TimeInterval) {
        print("⏩ Seek to: \(time) sec")
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

        print("🎵 Cued track: \(name) from \(source)")
        PlayerControlsView.shared?.nowPlayingText("Ready: \(name.replacingOccurrences(of: "_", with: " ").capitalized)")
    }

    // ✅ NEW METHOD: Play a track from the playlist directly
    func playTrackFromPlaylist(named trackName: String) {
        currentSource = .playlist
        currentTrackName = trackName

        if let url = Bundle.main.url(forResource: trackName, withExtension: "mp3", subdirectory: "Audio") {
            play(url: url)
            let displayName = trackName.replacingOccurrences(of: "_", with: " ").capitalized
            PlayerControlsView.shared?.nowPlayingText("Now Playing: \(displayName)")
        } else {
            print("⚠️ Could not find track in playlist: \(trackName)")
        }
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

        print("🎯 Playing cued track: \(trackName) from \(cuedSource)")

        let playNow = {
            self.play(url: url)
            self.currentSource = self.cuedSource
            PlayerControlsView.shared?.nowPlayingText("Now Playing: \(displayName)")
            PlayerControlsView.shared?.updatePlayButton(isPlaying: true)
        }

        if isPlaying {
            print("🔉 Fading out current track before playing cued track")
            startFadeOut {
                playNow()
            }
        } else {
            playNow()
        }
    }
    
    func playTrackFromPlaylist(at index: Int) {
        let playlist = SharedPlaylistManager.shared.playlist
        guard index >= 0 && index < playlist.count else {
            print("⚠️ Invalid playlist index: \(index)")
            return
        }

        let track = playlist[index]
        guard let url = Bundle.main.url(forResource: track, withExtension: "mp3", subdirectory: "Audio") else {
            print("❌ Could not find track in bundle: \(track)")
            return
        }

        currentSource = .playlist
        currentTrackName = track
        play(url: url)

        PlayerControlsView.shared?.nowPlayingText("Now Playing: \(track.replacingOccurrences(of: "_", with: " ").capitalized)")
        PlayerControlsView.shared?.updatePlayButton(isPlaying: true)
    }


    func cancelCue() {
        print("🛑 Cue cancelled: \(cuedTrackName ?? "nil")")
        cuedTrackURL = nil
        cuedTrackName = nil
        cuedSource = .none
    }

    func restartTrack() {
        print("🔁 Restarting current track")
        player?.currentTime = 0
        player?.play()
    }

    // MARK: - Library Navigation

    func playNextInLibrary() {
        guard let current = currentTrackName,
              let index = SharedLibraryManager.shared.libraryTracks.firstIndex(of: current),
              index + 1 < SharedLibraryManager.shared.libraryTracks.count else {
            print("⛔️ No next track in library")
            return
        }

        let nextTrack = SharedLibraryManager.shared.libraryTracks[index + 1]
        print("📂 Library Next: \(nextTrack)")

        if let url = SharedLibraryManager.shared.urlForTrack(named: nextTrack) {
            currentSource = .library
            play(url: url)
        }
    }

    func playPreviousInLibrary() {
        guard let current = currentTrackName,
              let index = SharedLibraryManager.shared.libraryTracks.firstIndex(of: current),
              index > 0 else {
            print("⛔️ No previous track in library")
            return
        }

        let prevTrack = SharedLibraryManager.shared.libraryTracks[index - 1]
        print("📂 Library Previous: \(prevTrack)")

        if let url = SharedLibraryManager.shared.urlForTrack(named: prevTrack) {
            currentSource = .library
            play(url: url)
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
                print("🔇 Fade out complete")
                completion()
            }
        }
    }

    // MARK: - 20 Second Limiter for Non-Members

    private func maybeStartPlaybackLimiter() {
        playbackLimitTimer?.invalidate()

        let isMember = UserDefaults.standard.bool(forKey: "isMember")
        if !isMember {
            print("⏱ Starting 20-second limiter for guest user")
            playbackLimitTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.isPlaying {
                    print("🔒 Time limit reached — stopping playback")
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

