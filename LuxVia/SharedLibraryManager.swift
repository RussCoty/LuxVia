import Foundation


class SharedLibraryManager {
    static let shared = SharedLibraryManager()

    var allSongs: [SongEntry] = []
    
    var allReadings: [Lyric] {
        return LyricsSyncManager.shared.loadCachedLyrics()
    }


    func urlForTrack(named name: String) -> URL? {
        print("[DEBUG] urlForTrack called with name: \(name)")
        let ext = (name as NSString).pathExtension.lowercased()
        let baseName = (name as NSString).deletingPathExtension

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
                .appendingPathComponent(name)

            print("[DEBUG] Checking imported: \(importedURL.path)")
            if FileManager.default.fileExists(atPath: importedURL.path) {
                print("[DEBUG] Found imported: \(importedURL.path)")
                return importedURL
            } else {
                print("[DEBUG] Not found imported: \(importedURL.path)")
            }

            // 3. Check custom recordings in Documents/audio/recordings/
            let recordingsDir = docsURL.appendingPathComponent("audio/recordings")
            let recordingsFile = recordingsDir.appendingPathComponent(name)
            print("[DEBUG] Checking recordingsDir: \(recordingsDir.path)")
            if let recordingsFiles = try? FileManager.default.contentsOfDirectory(atPath: recordingsDir.path) {
                print("[DEBUG] recordingsDir contents: \(recordingsFiles)")
            } else {
                print("[DEBUG] Could not list recordingsDir contents")
            }
            if FileManager.default.fileExists(atPath: recordingsFile.path) {
                print("[DEBUG] Found custom recording in recordingsDir: \(recordingsFile.path)")
                return recordingsFile
            }

            // 4. Fallback: check all files in Documents/audio/ for a matching filename
            let audioDirURL = docsURL.appendingPathComponent("audio")
            if let audioFiles = try? FileManager.default.contentsOfDirectory(atPath: audioDirURL.path) {
                print("[DEBUG] Fallback: checking audio dir for \(name)")
                for file in audioFiles {
                    print("[DEBUG] Found file in audio dir: \(file)")
                    if file == name {
                        let foundURL = audioDirURL.appendingPathComponent(file)
                        print("[DEBUG] Fallback found: \(foundURL.path)")
                        return foundURL
                    }
                }
            } else {
                print("[DEBUG] Could not list audio dir: \(audioDirURL.path)")
            }
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
