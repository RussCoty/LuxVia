// File: Models/BookletInfo.swift

import Foundation

struct BookletInfo {
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
}
