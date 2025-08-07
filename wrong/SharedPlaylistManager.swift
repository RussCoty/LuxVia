// File: SharedPlaylistManager.swift

import Foundation

class SharedPlaylistManager {
    static let shared = SharedPlaylistManager()

    // MARK: - Properties

    var playlist: [SongEntry] = []
    private(set) var currentIndex: Int = 0

    private let playlistKey = "sharedPlaylist"

    // MARK: - Init

    private init() {
        load()
    }

    // MARK: - Playback

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

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(playlist)
            UserDefaults.standard.set(data, forKey: playlistKey)
        } catch {
            print("Error saving playlist: \(error)")
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: playlistKey) {
            do {
                playlist = try JSONDecoder().decode([SongEntry].self, from: data)
            } catch {
                print("Error loading playlist: \(error)")
            }
        }
    }
}
