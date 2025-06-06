import Foundation

class SharedPlaylistManager {
    static let shared = SharedPlaylistManager()
    private init() {}

    var playlist: [String] = []
    private(set) var currentIndex: Int = 0

    func play(at index: Int) {
        guard index >= 0, index < playlist.count else { return }
        currentIndex = index
        let track = playlist[index]
        AudioPlayerManager.shared.playTrackFromPlaylist(named: track)
    }

    func playNext() {
        let nextIndex = currentIndex + 1
        guard nextIndex < playlist.count else { return }
        play(at: nextIndex)
    }

    func playPrevious() {
        let prevIndex = currentIndex - 1
        guard prevIndex >= 0 else { return }
        play(at: prevIndex)
    }

    func indexOfCurrentTrack() -> Int? {
        return playlist.firstIndex(of: AudioPlayerManager.shared.currentTrackName ?? "")
    }
}
