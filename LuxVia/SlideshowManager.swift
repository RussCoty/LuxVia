//
//  SlideshowManager.swift
//  LuxVia
//
//  Created on 16/11/2025.
//

import Foundation
import UIKit
import AVFoundation

class SlideshowManager {
    static let shared = SlideshowManager()
    
    // MARK: - Properties
    private var currentPlaylist: SlideshowPlaylist?
    private var currentSlideIndex: Int = 0
    private var displayTimer: Timer?
    private var isPlaying: Bool = false
    private var externalWindow: UIWindow?
    private var slideshowViewController: AirPlaySlideshowViewController?
    
    // Notifications
    static let slideshowDidStart = Notification.Name("SlideshowDidStart")
    static let slideshowDidStop = Notification.Name("SlideshowDidStop")
    static let slideshowDidUpdateSlide = Notification.Name("SlideshowDidUpdateSlide")
    
    // MARK: - File Management
    private var slideshowDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let slideshowPath = documentsPath.appendingPathComponent("Slideshows")
        
        if !FileManager.default.fileExists(atPath: slideshowPath.path) {
            try? FileManager.default.createDirectory(at: slideshowPath, withIntermediateDirectories: true)
        }
        
        return slideshowPath
    }
    
    private var playlistsFile: URL {
        return slideshowDirectory.appendingPathComponent("playlists.json")
    }
    
    // MARK: - Playlist Management
    private var playlists: [SlideshowPlaylist] = []
    
    init() {
        loadPlaylists()
        setupExternalDisplayObservers()
    }
    
    func loadPlaylists() {
        guard FileManager.default.fileExists(atPath: playlistsFile.path),
              let data = try? Data(contentsOf: playlistsFile),
              let decoded = try? JSONDecoder().decode([SlideshowPlaylist].self, from: data) else {
            playlists = []
            return
        }
        playlists = decoded
    }
    
    func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            try? encoded.write(to: playlistsFile)
        }
    }
    
    func getAllPlaylists() -> [SlideshowPlaylist] {
        return playlists
    }
    
    func createPlaylist(name: String) -> SlideshowPlaylist {
        let playlist = SlideshowPlaylist(name: name)
        playlists.append(playlist)
        savePlaylists()
        return playlist
    }
    
    func updatePlaylist(_ playlist: SlideshowPlaylist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
            savePlaylists()
        }
    }
    
    func deletePlaylist(_ playlist: SlideshowPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    // MARK: - Media File Management
    func saveMediaFile(data: Data, fileName: String) -> URL? {
        let fileURL = slideshowDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("❌ Failed to save media file: \(error)")
            return nil
        }
    }
    
    func getMediaURL(for fileName: String) -> URL {
        return slideshowDirectory.appendingPathComponent(fileName)
    }
    
    func deleteMediaFile(fileName: String) {
        let fileURL = slideshowDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Slideshow Playback
    func startSlideshow(playlist: SlideshowPlaylist) {
        guard !playlist.slides.isEmpty else {
            print("⚠️ Cannot start slideshow: no slides in playlist")
            return
        }
        
        stopSlideshow()
        
        currentPlaylist = playlist
        currentSlideIndex = 0
        isPlaying = true
        
        setupExternalDisplay()
        displayCurrentSlide()
        
        NotificationCenter.default.post(name: SlideshowManager.slideshowDidStart, object: nil)
    }
    
    func stopSlideshow() {
        displayTimer?.invalidate()
        displayTimer = nil
        isPlaying = false
        currentPlaylist = nil
        currentSlideIndex = 0
        
        teardownExternalDisplay()
        
        NotificationCenter.default.post(name: SlideshowManager.slideshowDidStop, object: nil)
    }
    
    func pauseSlideshow() {
        displayTimer?.invalidate()
        displayTimer = nil
        isPlaying = false
    }
    
    func resumeSlideshow() {
        guard currentPlaylist != nil else { return }
        isPlaying = true
        displayCurrentSlide()
    }
    
    func nextSlide() {
        guard let playlist = currentPlaylist else { return }
        
        currentSlideIndex += 1
        
        if currentSlideIndex >= playlist.slides.count {
            if playlist.settings.loopEnabled {
                currentSlideIndex = 0
            } else {
                stopSlideshow()
                return
            }
        }
        
        displayCurrentSlide()
    }
    
    func previousSlide() {
        guard currentPlaylist != nil else { return }
        
        currentSlideIndex -= 1
        
        if currentSlideIndex < 0 {
            currentSlideIndex = 0
        }
        
        displayCurrentSlide()
    }
    
    private func displayCurrentSlide() {
        guard let playlist = currentPlaylist,
              currentSlideIndex < playlist.slides.count else { return }
        
        let slide = playlist.slides[currentSlideIndex]
        
        // Update the external display
        slideshowViewController?.displaySlide(slide)
        
        // Notify observers
        NotificationCenter.default.post(
            name: SlideshowManager.slideshowDidUpdateSlide,
            object: nil,
            userInfo: ["slide": slide, "index": currentSlideIndex]
        )
        
        // Schedule next slide (for images, videos handle themselves)
        if slide.type == .image {
            displayTimer?.invalidate()
            displayTimer = Timer.scheduledTimer(withTimeInterval: slide.duration, repeats: false) { [weak self] _ in
                self?.nextSlide()
            }
        }
    }
    
    // MARK: - External Display Management
    private func setupExternalDisplayObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalDisplayDidConnect),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalDisplayDidDisconnect),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }
    
    @objc private func externalDisplayDidConnect(notification: Notification) {
        print("🖥️ External display connected")
        if isPlaying {
            setupExternalDisplay()
        }
    }
    
    @objc private func externalDisplayDidDisconnect(notification: Notification) {
        print("🖥️ External display disconnected")
        teardownExternalDisplay()
    }
    
    private func setupExternalDisplay() {
        // Check if there's an external screen available
        guard let externalScreen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else {
            print("⚠️ No external display found")
            return
        }
        
        // Create window for external display
        externalWindow = UIWindow(frame: externalScreen.bounds)
        externalWindow?.screen = externalScreen
        
        // Create and set the slideshow view controller
        slideshowViewController = AirPlaySlideshowViewController()
        externalWindow?.rootViewController = slideshowViewController
        externalWindow?.isHidden = false
        
        print("✅ External display setup complete")
    }
    
    private func teardownExternalDisplay() {
        externalWindow?.isHidden = true
        externalWindow = nil
        slideshowViewController = nil
    }
    
    // MARK: - State
    func isCurrentlyPlaying() -> Bool {
        return isPlaying
    }
    
    func getCurrentPlaylist() -> SlideshowPlaylist? {
        return currentPlaylist
    }
    
    func getCurrentSlideIndex() -> Int {
        return currentSlideIndex
    }
}
