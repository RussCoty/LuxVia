//
//  Models.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/08/2025.
//

import Foundation

enum LyricType: String, Codable {
    case reading
    case lyric
}
struct Lyric: Codable {
    let uid: Int?
    let title: String
    let body: String
    let type: LyricType
    let audioFileName: String?
    let category: String?
}

struct SongEntry: Codable, Equatable {
    let title: String
    let fileName: String
    let artist: String?
    let duration: TimeInterval?
}

struct ReadingEntry: Codable, Equatable {
    let title: String
    let text: String
}
