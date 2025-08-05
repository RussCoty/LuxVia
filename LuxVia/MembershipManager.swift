//
//  MembershipManager.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 16/05/2025.
//

import Foundation

class MembershipManager {
    static let shared = MembershipManager()
    private init() {}

    var isMember: Bool {
        return UserDefaults.standard.bool(forKey: "isMember")
    }

    func checkStatus(completion: (() -> Void)? = nil) {
        guard let url = URL(string: "https://funeralmusic.co.uk/wp-json/funeralmusic/v1/membership-status") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // 🔐 Include JWT token if available
        if let token = KeychainHelper.standard.read(service: "jwt", account: "funeralmusic") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let isMember = json["is_member"] as? Bool else {
                print("❌ Failed to fetch/parse membership")
                completion?()
                return
            }

            print("✅ Membership API result: \(isMember)")
            UserDefaults.standard.set(isMember, forKey: "isMember")
            completion?()
        }.resume()
    }
}
