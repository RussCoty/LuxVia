import Foundation
import AVFoundation

class AudioPlayerManager {
    static let shared = AudioPlayerManager()
    private init() {}

    var player: AVAudioPlayer?

    /// Current global volume (0.0 to 1.0) 
    var volume: Float = 0.75 {
        didSet {
            player?.volume = volume
        }
    }

    /// Name of the currently playing track (without extension)
    var currentTrackName: String?

    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }

    var currentTime: TimeInterval {
        return player?.currentTime ?? 0
    }

    var duration: TimeInterval {
        return player?.duration ?? 1
    }

    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
            
            // ✅ Store the name of the currently playing track
            currentTrackName = url.deletingPathExtension().lastPathComponent
        } catch {
            print("Error playing audio: \(error)")
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
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
    }
}
