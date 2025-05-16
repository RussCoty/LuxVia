//
//  MembershipManager.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 16/05/2025.
//

import WebKit

class MembershipManager {
    static let shared = MembershipManager()
    private init() {}

    var isMember: Bool {
        return UserDefaults.standard.bool(forKey: "isMember")
    }

    func checkStatus(in webView: WKWebView, completion: (() -> Void)? = nil) {
        webView.evaluateJavaScript("document.getElementById('nonce')?.innerText") { result, error in
            guard let nonce = result as? String else {
                print("❌ Could not read nonce: \(error?.localizedDescription ?? "nil result")")
                completion?()
                return
            }

            print("✅ Got nonce: \(nonce)")
            self.queryAPI(using: nonce, completion: completion)
        }
    }

    private func queryAPI(using nonce: String, completion: (() -> Void)?) {
        guard let url = URL(string: "https://funeralmusic.co.uk/wp-json/funeralmusic/v1/membership-status") else { return }

        var request = URLRequest(url: url)
        request.setValue(nonce, forHTTPHeaderField: "X-WP-Nonce")

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

