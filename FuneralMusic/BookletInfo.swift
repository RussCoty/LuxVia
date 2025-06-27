// File: Models/BookletInfo.swift

import Foundation

struct BookletInfo: Codable {
    // Personal Details
    var userName: String
    var userEmail: String

    // Deceased
    var deceasedName: String
    var dateOfBirth: Date
    var dateOfPassing: Date
    var photo: Data?

    // Service Info
    var location: String
    var dateOfService: Date
    var timeHour: Int
    var timeMinute: Int
    var celebrantName: String

    // Optional Sections
    var committalLocation: String?
    var wakeLocation: String?
    var donationInfo: String?
    var pallbearers: String?
    var photographer: String?

    // Persistence
    private static let storageKey = "savedBookletInfo"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func load() -> BookletInfo? {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let info = try? JSONDecoder().decode(BookletInfo.self, from: data) {
            return info
        }
        return nil
    }
}
