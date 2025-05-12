import Foundation

class SharedPlaylistManager {
    static let shared = SharedPlaylistManager()
    private init() {}

    var playlist: [String] = []
}

