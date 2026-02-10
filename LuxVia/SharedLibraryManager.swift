import Foundation


class SharedLibraryManager {
    static let shared = SharedLibraryManager()

    var allSongs: [SongEntry] = []
    
    var allReadings: [Lyric] {
        return CSVLyricsLoader.shared.loadLyrics().filter { $0.type == .reading }
    }

    var allLyrics: [Lyric] {
        return CSVLyricsLoader.shared.loadLyrics().filter { $0.type == .lyric }
    }


    func urlForTrack(named name: String) -> URL? {
    print("[DEBUG] urlForTrack called with name: \(name)")

        // 1. Check bundle Audio directory - use direct file enumeration for reliability
        if let bundleURL = Bundle.main.resourceURL?.appendingPathComponent("Audio") {
            let fileManager = FileManager.default
            print("[DEBUG] [BUNDLE] Checking Audio folder: \(bundleURL.path)")
            
            if fileManager.fileExists(atPath: bundleURL.path) {
                // First try exact match
                let exactURL = bundleURL.appendingPathComponent(name)
                if fileManager.fileExists(atPath: exactURL.path) {
                    print("[DEBUG] [BUNDLE] ✅ Found exact match: \(exactURL.path)")
                    return exactURL
                }
                
                // Then try case-insensitive match
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: bundleURL.path)
                    let targetFileName = name.lowercased()
                    for file in contents {
                        if file.lowercased() == targetFileName {
                            let fullPath = bundleURL.appendingPathComponent(file)
                            print("[DEBUG] [BUNDLE] ✅ Found case-insensitive match: \(fullPath.path)")
                            return fullPath
                        }
                    }
                    print("[DEBUG] [BUNDLE] ❌ Not found in bundle Audio folder. Searched for: \(name)")
                } catch {
                    print("[DEBUG] [BUNDLE] Error reading Audio folder: \(error)")
                }
            } else {
                print("[DEBUG] [BUNDLE] ❌ Audio folder does not exist at: \(bundleURL.path)")
            }
        } else {
            print("[DEBUG] [BUNDLE] ❌ Could not construct Audio folder URL")
        }

        // 2. Check imported files in Documents/audio/imported/
        if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileManager = FileManager.default

            // Ensure audio directory exists
            let audioDirURL = docsURL.appendingPathComponent("audio")
            if !fileManager.fileExists(atPath: audioDirURL.path) {
                do {
                    try fileManager.createDirectory(at: audioDirURL, withIntermediateDirectories: true, attributes: nil)
                    print("[DEBUG] [DIR] Created audio directory: \(audioDirURL.path)")
                } catch {
                    print("[ERROR] [DIR] Failed to create audio directory: \(audioDirURL.path), error: \(error)")
                }
            } else {
                print("[DEBUG] [DIR] Audio directory exists: \(audioDirURL.path)")
            }

            // Ensure recordings directory exists
            let recordingsDir = audioDirURL.appendingPathComponent("recordings")
            if !fileManager.fileExists(atPath: recordingsDir.path) {
                do {
                    try fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true, attributes: nil)
                    print("[DEBUG] [DIR] Created recordings directory: \(recordingsDir.path)")
                } catch {
                    print("[ERROR] [DIR] Failed to create recordings directory: \(recordingsDir.path), error: \(error)")
                }
            } else {
                print("[DEBUG] [DIR] Recordings directory exists: \(recordingsDir.path)")
            }

            let importedURL = audioDirURL
                .appendingPathComponent("imported")
                .appendingPathComponent(name)

            print("[DEBUG] [IMPORTED] Checking imported: \(importedURL.path)")
            if fileManager.fileExists(atPath: importedURL.path) {
                print("[DEBUG] [IMPORTED] Found imported: \(importedURL.path)")
                return importedURL
            } else {
                print("[DEBUG] [IMPORTED] Not found imported: \(importedURL.path)")
            }

            // 3. Check custom recordings in Documents/audio/recordings/
            let recordingsFile = recordingsDir.appendingPathComponent(name)
            print("[DEBUG] [RECORDINGS] Checking recordingsDir: \(recordingsDir.path)")
            if let recordingsFiles = try? fileManager.contentsOfDirectory(atPath: recordingsDir.path) {
                print("[DEBUG] [RECORDINGS] recordingsDir contents: \(recordingsFiles)")
            } else {
                print("[DEBUG] [RECORDINGS] Could not list recordingsDir contents")
            }
            if fileManager.fileExists(atPath: recordingsFile.path) {
                print("[DEBUG] [RECORDINGS] Found custom recording in recordingsDir: \(recordingsFile.path)")
                return recordingsFile
            } else {
                print("[DEBUG] [RECORDINGS] Not found custom recording: \(recordingsFile.path)")
            }

            // 4. Fallback: check all files in Documents/audio/ for a matching filename
            if let audioFiles = try? fileManager.contentsOfDirectory(atPath: audioDirURL.path) {
                print("[DEBUG] [FALLBACK] Fallback: checking audio dir for \(name)")
                for file in audioFiles {
                    print("[DEBUG] [FALLBACK] Found file in audio dir: \(file)")
                    if file == name {
                        let foundURL = audioDirURL.appendingPathComponent(file)
                        print("[DEBUG] [FALLBACK] Fallback found: \(foundURL.path)")
                        return foundURL
                    }
                }
                print("[DEBUG] [FALLBACK] No matching file found in audio dir for \(name)")
            } else {
                print("[DEBUG] [FALLBACK] Could not list audio dir: \(audioDirURL.path)")
            }
        }

    print("[DEBUG] [RESULT] urlForTrack: returning nil for \(name)")
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
