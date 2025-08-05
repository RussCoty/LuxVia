//
//  Untitled 2.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/08/2025.
//

import Foundation

class CSVLyricsLoader {

    func loadLyrics() -> [Lyric] {
        guard let url = Bundle.main.url(forResource: "lyrics", withExtension: "csv") else {
            print("📛 CSV file not found in bundle")
            return []
        }

        do {
            let data = try String(contentsOf: url)
            var result: [Lyric] = []

            let lines = data.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() where !line.trimmingCharacters(in: .whitespaces).isEmpty && index > 0 {
                let components = line.components(separatedBy: ",")
                guard components.count >= 4 else {
                    print("⚠️ Invalid row at \(index): \(line)")
                    continue
                }

                let title = components[0].trimmingCharacters(in: .whitespaces)
                let body = components[1].trimmingCharacters(in: .whitespaces)
                let fileName = components[2].trimmingCharacters(in: .whitespaces)
                let typeRaw = components[3].trimmingCharacters(in: .whitespaces)

                guard let type = Lyric.LyricType(rawValue: typeRaw.lowercased()) else {
                    print("⚠️ Unknown type at \(index): \(typeRaw)")
                    continue
                }

                result.append(Lyric(title: title, body: body, audioFileName: fileName.isEmpty ? nil : fileName, type: type))
            }

            print("✅ Loaded \(result.count) lyrics from CSV")
            return result
        } catch {
            print("❌ Failed to read CSV: \(error)")
            return []
        }
    }
}
