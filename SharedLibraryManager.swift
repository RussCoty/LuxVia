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
            // 1. Check bundle path
            if let path = Bundle.main.path(forResource: song.fileName, ofType: "mp3", inDirectory: "Audio") {
                return URL(fileURLWithPath: path)
            }

            // 2. Check imported files in Documents/audio/imported/
            if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let importedURL = docsURL
                    .appendingPathComponent("audio/imported")
                    .appendingPathComponent(song.fileName + ".mp3")

                if FileManager.default.fileExists(atPath: importedURL.path) {
                    return importedURL
                }
            }
        }

        return nil
    }


    func songForTrack(named name: String) -> SongEntry? {
        return allSongs.first(where: {
            $0.title.lowercased() == name.lowercased() ||
            $0.fileName.lowercased() == name.lowercased()
        })
    }
    
    func preloadAllReadings() {
        _ = LyricsSyncManager.shared.loadCachedLyrics()
        print("✅ Preloaded all lyrics from cache.")
    }

}
