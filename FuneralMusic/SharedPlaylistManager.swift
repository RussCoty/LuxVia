import Foundation

class SharedPlaylistManager {
    static let shared = SharedPlaylistManager()
    var playlist: [String] = []
    private init() {}
}
