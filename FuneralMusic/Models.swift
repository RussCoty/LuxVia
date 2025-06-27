import Foundation

struct LyricEntry: Codable {
    let title: String
    let body: String
    let url: String
    let musicFilename: String?
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
