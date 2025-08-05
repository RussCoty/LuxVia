//
//  Untitled.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/08/2025.
//

import Foundation

final class LyricsLibraryManager {
    static let shared = LyricsLibraryManager()

    private(set) var lyrics: [Lyric] = []

    private init() {}

    /// Loads lyrics from bundled CSV
    func loadLyricsFromCSV() {
        guard let url = Bundle.main.url(forResource: "lyrics", withExtension: "csv") else {
            print("❌ Could not find lyrics.csv in bundle.")
            return
        }

        do {
            let content = try String(contentsOf: url)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

            lyrics = lines.compactMap { Lyric(csvLine: $0) }
                          .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

            print("✅ Loaded \(lyrics.count) lyrics from CSV.")
            lyrics.prefix(10).forEach { print("• \($0.title) [\($0.type)]") }

        } catch {
            print("❌ Error reading lyrics CSV:", error)
        }
    }


    /// Finds a lyric by audio file name
    func lyric(forAudioFileName fileName: String) -> Lyric? {
        let normalizedFile = fileName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return lyrics.first {
            $0.audioFileName?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedFile
        }
    }

    /// Finds a lyric by title
    func lyric(forTitle title: String) -> Lyric? {
        let normalized = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return lyrics.first {
            $0.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }
    }
    
    private func loadLyrics() {
        guard let url = Bundle.main.url(forResource: "lyrics", withExtension: "csv") else {
            print("❌ Could not find lyrics.csv in bundle.")
            return
        }

        do {
            let content = try String(contentsOf: url)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

            lyrics = lines.compactMap { Lyric(csvLine: $0) }
                          .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }


            print("✅ Loaded \(lyrics.count) lyrics from CSV.")
        } catch {
            print("❌ Error reading lyrics CSV:", error)
        }
    }

}
