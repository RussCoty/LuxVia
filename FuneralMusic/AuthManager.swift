//
//  AuthManager.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 17/05/2025.
//

import Foundation

class AuthManager {
    static let shared = AuthManager()
    
    enum AuthState {
        case loggedIn
        case guest
    }

    private init() {}

    var isLoggedIn: Bool {
        return UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    var authState: AuthState {
        return isLoggedIn ? .loggedIn : .guest
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "guestMode") // 👈 NEW
        print("🔓 Logged out")
        NotificationCenter.default.post(name: .authStatusChanged, object: nil)
    }


    func login() {
        // Prevent accidental login during guest mode
        if UserDefaults.standard.bool(forKey: "guestMode") {
            print("🚫 Guest mode is active — skipping login")
            return
            }
        
            UserDefaults.standard.set(true, forKey: "loggedIn")
            print("🔐 Logged in")
            NotificationCenter.default.post(name: .authStatusChanged, object: nil)
    }
}
