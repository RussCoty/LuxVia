import Foundation


class SharedLibraryManager {
    static let shared = SharedLibraryManager()

    var allSongs: [SongEntry] = []
    
    var allReadings: [Lyric] {
        return LyricsSyncManager.shared.loadCachedLyrics()
    }


    func urlForTrack(named name: String) -> URL? {
        print("[DEBUG] urlForTrack called with name: \(name)")
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

                // 3. Check custom recordings in Documents/audio/recordings/
                let recordingsURL = docsURL
                    .appendingPathComponent("audio/recordings")
                    .appendingPathComponent(fileName)
                print("[DEBUG] Checking recordings: \(recordingsURL.path)")
                if FileManager.default.fileExists(atPath: recordingsURL.path) {
                    print("[DEBUG] Found recording: \(recordingsURL.path)")
                    return recordingsURL
                } else {
                    print("[DEBUG] Not found recording: \(recordingsURL.path)")
                }

                // 4. Fallback: check all files in Documents/audio/ for a matching filename
                let audioDirURL = docsURL.appendingPathComponent("audio")
                if let audioFiles = try? FileManager.default.contentsOfDirectory(atPath: audioDirURL.path) {
                    print("[DEBUG] Fallback: checking audio dir for \(fileName)")
                    for file in audioFiles {
                        print("[DEBUG] Found file in audio dir: \(file)")
                        if file == fileName {
                            let foundURL = audioDirURL.appendingPathComponent(file)
                            print("[DEBUG] Fallback found: \(foundURL.path)")
                            return foundURL
                        }
                    }
                } else {
                    print("[DEBUG] Could not list audio dir: \(audioDirURL.path)")
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
