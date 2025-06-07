// File: SharedPlaylistManager.swift

import Foundation

class SharedPlaylistManager {
    static let shared = SharedPlaylistManager()
    private init() {}

    var playlist: [SongEntry] = []
    private(set) var currentIndex: Int = 0

    func play(at index: Int) {
        guard index >= 0, index < playlist.count else { return }
        currentIndex = index
        AudioPlayerManager.shared.playTrackFromPlaylist(at: index)
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
        guard let name = AudioPlayerManager.shared.currentTrackName else { return nil }
        return playlist.firstIndex(where: { $0.title == name })
    }
}
