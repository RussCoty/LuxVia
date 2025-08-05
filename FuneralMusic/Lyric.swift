//
//  Lyric.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/08/2025.
//

import Foundation

struct Lyric {
    let title: String
    let body: String
    let audioFileName: String?
    let type: LyricType

    enum LyricType: String {
        case reading
        case lyric
    }
}
extension Lyric {
    init?(csvLine: String) {
        let parts = csvLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count >= 3 else { return nil }

        let title = parts[0]
        let body = parts[safe: 1] ?? ""
        let audioFileName = parts[safe: 2]
        let typeString = parts[safe: 3]?.lowercased() ?? "lyric"

        guard let type = LyricType(rawValue: typeString) else {
            print("⚠️ Unknown lyric type: \(typeString)")
            return nil
        }

        self.title = title
        self.body = body
        self.audioFileName = audioFileName
        self.type = type
    }
}
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
