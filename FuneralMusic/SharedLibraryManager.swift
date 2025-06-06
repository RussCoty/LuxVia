import Foundation

class SharedLibraryManager {
    static let shared = SharedLibraryManager()

    // This should be populated once when the app loads the library
    var libraryTracks: [String] = []

    // This helps AudioPlayerManager get the track file URL
    func urlForTrack(named name: String) -> URL? {
        // Check for imported files
        let fileManager = FileManager.default
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let importedURL = docsURL.appendingPathComponent("audio/imported/\(name).mp3")
            if fileManager.fileExists(atPath: importedURL.path) {
                return importedURL
            }
        }

        // Check the bundle
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") {
            return url
        }

        return nil
    }
}
