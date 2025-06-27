
# 🎵 FuneralMusic App – File Role Reference Guide

This document outlines the role of each Swift source file in your app, grouped by functionality for easy reference.

---

## 🚀 App Lifecycle

| File | Role |
|------|------|
| `AppDelegate.swift` | Sets up the app at launch, initializes services, handles app-wide lifecycle events. |
| `SceneDelegate.swift` | Manages UI window scenes; used especially in iOS 13+ for multitasking support. |
| `Info.plist` | Configuration file that defines app metadata, permissions, and launch settings. |

---

## 🔐 Authentication & Membership

| File | Role |
|------|------|
| `LoginViewController.swift` | Main login screen for users. |
| `NativeLoginViewController.swift` | Likely a custom login screen (Apple Sign-In, native flow, etc). |
| `AuthManager.swift` | Handles authentication state, login/logout flow, token storage. |
| `KeychainHelper.swift` | Securely stores credentials and tokens. |
| `NonceExtractor.swift` | Probably helps extract/verify secure nonces during sign-in (e.g., Apple ID). |
| `MembershipManager.swift` | Checks or stores member status (e.g., is user subscribed/premium?). |

---

## 🎧 Music & Playback

| File | Role |
|------|------|
| `LibraryViewController.swift` | Displays folder-based music list, supports import, search, and selection. |
| `PlaylistViewController.swift` | Shows a playlist of selected tracks. |
| `MusicTabViewController.swift` | Tab container that switches between Library and Playlist views. |
| `AudioPlayerManager.swift` | Manages AVAudioPlayer logic: cueing, playing, stopping, fading, member limit. |
| `SharedPlaylistManager.swift` | Singleton for maintaining current playlist across the app. |
| `PlayerControlsView.swift` | The now-playing UI footer with play/pause and track info. |
| `UIDocumentPickerViewController.swift` | Handles user file imports via iOS document picker. |

---

## 📋 Service Management

| File | Role |
|------|------|
| `OrderOfServiceViewController.swift` | Likely manages or shows an event schedule or running order (e.g., for a funeral). |
| `ViewController.swift` / `MainViewController.swift` | Likely launch point or dashboard controllers (used for routing). |

---

## 🧱 UI & Infrastructure

| File | Role |
|------|------|
| `TopBarView.swift` | Reusable top bar UI component with logout + optional segmented control. |
| `PaddedLabel.swift` | UILabel subclass with padding, often used in toasts or alerts. |
| `BaseViewController.swift` | Likely defines shared setup logic or UI defaults for all screens. |

---

## 🧹 Notes

- Files prefixed with `.__MACOSX/._` are macOS-generated metadata files and can be safely ignored or deleted.
- All audio import/export logic is sandboxed to `Documents/audio/imported/` and must be accessed via `FileManager`.

---


