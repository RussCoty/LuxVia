import Foundation
import AVFoundation

class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerManager()
    private override init() {
        super.init()
    }

    var player: AVAudioPlayer?
    private var playbackLimitTimer: Timer?
    private var fadeTimer: Timer?

    enum AudioSource {
        case none
        case library
        case playlist
    }

    var onPlaybackEnded: (() -> Void)?

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

    var cuedTrack: SongEntry?
    var cuedSource: AudioSource = .none

    var isTrackCued: Bool {
        return cuedTrack != nil
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

    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
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
        cuedTrack = nil
        playbackLimitTimer?.invalidate()
    }

    func cueTrack(_ song: SongEntry, source: AudioSource) {
        cuedTrack = song
        cuedSource = source
    }

    func playCuedTrack() {
        guard let song = cuedTrack else {
            return
        }

        if let url = SharedLibraryManager.shared.urlForTrack(named: song.fileName) {
            play(url: url)
            currentTrackName = song.title
            currentSource = cuedSource
            cuedTrack = nil
        }
    }

    func playTrackFromPlaylist(at index: Int) {
        let playlist = SharedPlaylistManager.shared.playlist
        guard index >= 0 && index < playlist.count else {
            return
        }

        let track = playlist[index]
        if let url = SharedLibraryManager.shared.urlForTrack(named: track.fileName) {
            currentSource = .playlist
            currentTrackName = track.title
            play(url: url)
        }
    }

    func playNextInLibrary() {
        guard let current = currentTrackName else { return }
        guard let index = SharedLibraryManager.shared.allSongs.firstIndex(where: { $0.title == current }),
              index + 1 < SharedLibraryManager.shared.allSongs.count else {
            return
        }

        let nextTrack = SharedLibraryManager.shared.allSongs[index + 1]
        if let url = SharedLibraryManager.shared.urlForTrack(named: nextTrack.fileName) {
            currentSource = .library
            play(url: url)
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
    }

    func playPreviousInLibrary() {
        guard let current = currentTrackName else { return }
        guard let index = SharedLibraryManager.shared.allSongs.firstIndex(where: { $0.title == current }),
              index > 0 else {
            return
        }

        let prevTrack = SharedLibraryManager.shared.allSongs[index - 1]
        if let url = SharedLibraryManager.shared.urlForTrack(named: prevTrack.fileName) {
            currentSource = .library
            play(url: url)
        }
    }

    func cancelCue() {
        cuedTrack = nil
        cuedSource = .none
    }

    func restartTrack() {
        player?.currentTime = 0
        player?.play()
    }

    private func maybeStartPlaybackLimiter() {
        playbackLimitTimer?.invalidate()
        let isMember = UserDefaults.standard.bool(forKey: "isMember")
        if !isMember {
            playbackLimitTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.isPlaying {
                    self.startFadeOut {
                        self.stop()
                    }
                }
            }
        }
    }

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
                let title = self.currentTrackName ?? "—"
                player.volume = self.volume  // Restore volume first
                DispatchQueue.main.async {
                    PlayerControlsView.shared?.nowPlayingText("Paused after fade: \(title)")
                }
                player.stop()  // Stop only after UI update
                completion()
            }
        }
    }




    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🔚 Playback finished")
        onPlaybackEnded?()
    }
}
