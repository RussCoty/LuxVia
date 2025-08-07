// CSVLyricsLoader.swift
import Foundation
import CodableCSV

final class CSVLyricsLoader {
    static let shared = CSVLyricsLoader()

    private init() {}

    func loadLyrics() -> [Lyric] {
        guard let url = Bundle.main.url(forResource: "lyrics", withExtension: "csv") else {
            print("📛 CSV file not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)

            let decoder = CSVDecoder {
                $0.headerStrategy = .firstLine
                $0.bufferingStrategy = .sequential
                $0.trimStrategy = .whitespaces
            }

            let rawLyrics = try decoder.decode([RawLyricRow].self, from: data)

            let entries: [Lyric] = rawLyrics.compactMap { row -> Lyric? in
                guard let type = LyricType(rawValue: row.type.lowercased()) else {
                    print("⚠️ Unknown lyric type: \(row.type)")
                    return nil
                }

                guard !row.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return nil
                }

                return Lyric(
                    title: row.title,
                    body: row.content,
                    type: type,
                    audioFileName: row.audio_file_name.isEmpty ? nil : row.audio_file_name
                )
            }

            print("✅ Loaded \(entries.count) lyrics from CSV")
            print("🗂️ Dumping all loaded lyrics with audioFileName:")
            for lyric in entries {
                print(" • title = '\(lyric.title)', audioFileName = '\(lyric.audioFileName ?? "nil")'")
            }

            return entries

        } catch {
            print("❌ Failed to parse lyrics.csv: \(error)")
            return []
        }
    }
}

// Matches CSV header
struct RawLyricRow: Codable {
    let title: String
    let content: String
    let type: String
    let audio_file_name: String
}
