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
            let fileName = song.fileName
            let ext = (fileName as NSString).pathExtension.lowercased()
            let baseName = (fileName as NSString).deletingPathExtension

            print("[DEBUG] Looking for track: \(fileName) (ext: \(ext), base: \(baseName))")

            // 1. Check bundle path
            if let path = Bundle.main.path(forResource: baseName, ofType: ext, inDirectory: "Audio") {
                print("[DEBUG] Found in bundle: \(path)")
                return URL(fileURLWithPath: path)
            } else {
                print("[DEBUG] Not found in bundle: \(baseName).\(ext)")
            }

            // 2. Check imported files in Documents/audio/imported/
            if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let importedURL = docsURL
                    .appendingPathComponent("audio/imported")
                    .appendingPathComponent(fileName)

                print("[DEBUG] Checking imported: \(importedURL.path)")
                if FileManager.default.fileExists(atPath: importedURL.path) {
                    print("[DEBUG] Found imported: \(importedURL.path)")
                    return importedURL
                } else {
                    print("[DEBUG] Not found imported: \(importedURL.path)")
                }
            }
        } else {
            print("[DEBUG] No song found for: \(name)")
        }

        print("[DEBUG] urlForTrack: returning nil for \(name)")
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
