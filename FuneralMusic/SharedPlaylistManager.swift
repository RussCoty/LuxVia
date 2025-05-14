import Foundation

class SharedPlaylistManager {
    static let shared = SharedPlaylistManager()

    private let storageKey = "playlistTracks"

    var playlist: [String] = [] {
        didSet {
            savePlaylist()
        }
    }

    private init() {
        loadPlaylist()
    }

    private func savePlaylist() {
        UserDefaults.standard.set(playlist, forKey: storageKey)
    }

    private func loadPlaylist() {
        if let saved = UserDefaults.standard.stringArray(forKey: storageKey) {
            playlist = saved
        }
    }
}
