import Foundation


class SharedLibraryManager {
    static let shared = SharedLibraryManager()

    var allSongs: [SongEntry] = []
    
    var allReadings: [Lyric] {
        return LyricsSyncManager.shared.loadCachedLyrics()
    }


    func urlForTrack(named name: String) -> URL? {
        // Match by title or filename, ignoring case
        if let song = allSongs.first(where: {
            $0.title.lowercased() == name.lowercased() ||
            $0.fileName.lowercased() == name.lowercased()
        }) {
            // Looks inside 'Audio/' folder in bundle
            let path = Bundle.main.path(forResource: song.fileName, ofType: "mp3", inDirectory: "Audio")
            return path != nil ? URL(fileURLWithPath: path!) : nil
        }
        return nil
    }


    func songForTrack(named name: String) -> SongEntry? {
        return allSongs.first(where: {
            $0.title.lowercased() == name.lowercased() ||
            $0.fileName.lowercased() == name.lowercased()
        })
    }
    
    
}
