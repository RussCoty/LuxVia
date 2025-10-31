#!/usr/bin/swift

// Simple test script to verify the music count logic
import Foundation

// Simulate what the MusicViewController would show
func testMusicCount() {
    // This simulates the CSV parsing
    let csvPath = "/workspaces/LuxVia/LuxVia/lyrics.csv"
    
    guard let csvContent = try? String(contentsOfFile: csvPath) else {
        print("❌ Cannot read CSV file")
        return
    }
    
    let lines = csvContent.components(separatedBy: .newlines)
    var musicEntries: [String] = []
    
    for line in lines {
        let columns = line.components(separatedBy: ",")
        if columns.count >= 5 && columns[3].trimmingCharacters(in: .whitespacesAndNewlines) == "lyric" {
            let audioFileName = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
            if !audioFileName.isEmpty && (audioFileName.hasSuffix(".mp3") || audioFileName.hasSuffix(".wav")) {
                let title = columns[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                musicEntries.append("\(title) -> \(audioFileName)")
            }
        }
    }
    
    print("🎵 Music entries that would be shown:")
    print("📊 Total count: \(musicEntries.count)")
    for (index, entry) in musicEntries.enumerated() {
        print("\(index + 1). \(entry)")
    }
}

testMusicCount()