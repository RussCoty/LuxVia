//
//  AuthManager.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 17/05/2025.
//

import Foundation

class AuthManager {
    static let shared = AuthManager()

    private init() {}

    var isLoggedIn: Bool {
        return UserDefaults.standard.bool(forKey: "loggedIn")
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "loggedIn")
        print("🔓 Logged out")
        NotificationCenter.default.post(name: .authStatusChanged, object: nil)
    }

    func login() {
        UserDefaults.standard.set(true, forKey: "loggedIn")
        print("🔐 Logged in")
        NotificationCenter.default.post(name: .authStatusChanged, object: nil)
    }
}
