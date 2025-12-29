// AudioPlayerManager.swift

import Foundation
import AVFoundation

class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerManager()
    private override init() {
        super.init()

        do {
            // Configure audio session to allow independent routing
            // .allowAirPlay enables audio to route to AirPlay devices separately from video
            // .allowBluetoothA2DP enables Bluetooth audio devices
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ AVAudioSession set for background & silent switch playback with independent audio routing")
        } catch {
            print("❌ Failed to set AVAudioSession:", error)
        }
    }
    

    var player: AVAudioPlayer?
    private var playbackLimitTimer: Timer?
    private var fadeTimer: Timer?

    enum AudioSource {
        case none, library, playlist
    }

    var onPlaybackEnded: (() -> Void)?
    var onStateChanged: (() -> Void)?  // ✅ Sync UI callback

    var currentSource: AudioSource = .none
    var currentTrackName: String?
    var volume: Float = 0.35 {
        didSet {
            player?.volume = volume
            onStateChanged?()  // ✅ Trigger UI update
        }
    }

    var cuedTrack: SongEntry?
    var cuedSource: AudioSource = .none

    var isTrackCued: Bool { cuedTrack != nil }
    var isPaused: Bool { player?.isPlaying == false && player != nil }
    var isStopped: Bool { player == nil }
    var isPlaying: Bool { player?.isPlaying ?? false }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    var duration: TimeInterval { player?.duration ?? 1 }

    var currentTrack: SongEntry? {
        guard let name = currentTrackName else { return nil }
        // Match by fileName instead of title to support extensions
        return SharedLibraryManager.shared.allSongs.first { $0.fileName == name }
    }

    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.delegate = self
            player?.prepareToPlay()
            //Background play capabilities with independent audio routing.
            try? AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetoothA2DP]
            )
            try? AVAudioSession.sharedInstance().setActive(true)

            player?.play()

            maybeStartPlaybackLimiter()
            onStateChanged?()  // ✅
        } catch {
            print("❌ Error playing audio: \(error)")
        }
    }

    func pause() {
        player?.pause()
        playbackLimitTimer?.invalidate()
        onStateChanged?()  // ✅
    }

    func resume() {
        player?.play()
        maybeStartPlaybackLimiter()
        onStateChanged?()  // ✅
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTrackName = nil
        cuedTrack = nil
        playbackLimitTimer?.invalidate()
        onStateChanged?()  // ✅
    }

    func cueTrack(_ song: SongEntry, source: AudioSource) {
        cuedTrack = song
        cuedSource = source
        onStateChanged?()  // ✅
    }

    func playCuedTrack() {
        guard let song = cuedTrack,
              let url = SharedLibraryManager.shared.urlForTrack(named: song.fileName) else {
            return
        }

        play(url: url)
        currentTrackName = song.fileName // Use fileName (with extension) for playback
        currentSource = cuedSource
        cuedTrack = nil
        cuedSource = .none
        onStateChanged?()  // ✅
    }

    func playTrackFromPlaylist(at index: Int) {
        let playlist = SharedPlaylistManager.shared.playlist
        guard index >= 0, index < playlist.count else { return }

        let track = playlist[index]
        if let url = SharedLibraryManager.shared.urlForTrack(named: track.fileName) {
            currentSource = .playlist
            currentTrackName = track.title
            play(url: url)
            onStateChanged?()  // ✅
        }
    }

    func playNextInLibrary() {
        guard let current = currentTrackName,
              let index = SharedLibraryManager.shared.allSongs.firstIndex(where: { $0.title == current }),
              index + 1 < SharedLibraryManager.shared.allSongs.count else {
            return
        }

        let nextTrack = SharedLibraryManager.shared.allSongs[index + 1]
        if let url = SharedLibraryManager.shared.urlForTrack(named: nextTrack.fileName) {
            currentSource = .library
            currentTrackName = nextTrack.title
            play(url: url)
            onStateChanged?()
        }
    }

    func playPreviousInLibrary() {
        guard let current = currentTrackName,
              let index = SharedLibraryManager.shared.allSongs.firstIndex(where: { $0.title == current }),
              index > 0 else {
            return
        }

        let prevTrack = SharedLibraryManager.shared.allSongs[index - 1]
        if let url = SharedLibraryManager.shared.urlForTrack(named: prevTrack.fileName) {
            currentSource = .library
            currentTrackName = prevTrack.title
            play(url: url)
            onStateChanged?()
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        onStateChanged?()
    }

    func cancelCue() {
        cuedTrack = nil
        cuedSource = .none
        onStateChanged?()
    }

    func restartTrack() {
        player?.currentTime = 0
        player?.play()
        onStateChanged?()
    }

    private func maybeStartPlaybackLimiter() {
        playbackLimitTimer?.invalidate()
        let isMember = UserDefaults.standard.bool(forKey: "isMember")
        if !isMember {
            playbackLimitTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: false) { [weak self] _ in
                guard let self = self, self.isPlaying else { return }
                self.startFadeOut {
                    self.stop()
                }
            }
        }
    }

    private func startFadeOut(completion: @escaping () -> Void) {
        fadeTimer?.invalidate()

        // ✅ Show "Fading Out" on the fade button
        DispatchQueue.main.async {
            PlayerControlsView.shared?.setFadeButtonTitle("Fading Out")

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                PlayerControlsView.shared?.setFadeButtonTitle("Fade")
            }
        }

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.player else {
                timer.invalidate()
                DispatchQueue.main.async {
                    PlayerControlsView.shared?.setFadeButtonTitle("Fade") // Reset on early cancel
                }
                completion()
                return
            }

            if player.volume > 0.05 {
                player.volume -= 0.05
            } else {
                timer.invalidate()
                player.volume = self.volume

                DispatchQueue.main.async {
                    PlayerControlsView.shared?.setFadeButtonTitle("Fade") // ✅ Reset button after fade
                    PlayerControlsView.shared?.updatePlayingTrackText("Paused after fade: \(self.currentTrackName ?? "—")")
                }

                player.stop()
                self.onStateChanged?()
                completion()
            }
        }
    }



    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🔚 Playback finished")
        onPlaybackEnded?()
        onStateChanged?()  // ✅
    }
}

