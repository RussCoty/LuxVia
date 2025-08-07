//
//  Untitled 2.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 27/07/2025.
//

import Foundation

extension String {
    /// Removes leading 2-digit track numbers and spaces (e.g., "01 Amazing Grace" → "Amazing Grace")
    var normalizedTitle: String {
        return self.replacingOccurrences(
            of: #"^\d{2}\s"#,
            with: "",
            options: .regularExpression
        ).lowercased()
    }
}
