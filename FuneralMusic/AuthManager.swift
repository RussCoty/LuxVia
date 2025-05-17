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
        // Change to real logic if needed
        return UserDefaults.standard.bool(forKey: "loggedIn")
    }

    func logout() {
        // Replace with your logout logic
        UserDefaults.standard.set(false, forKey: "loggedIn")
        print("🔓 Logged out")
    }

    func login() {
        // Optional helper
        UserDefaults.standard.set(true, forKey: "loggedIn")
    }
}

