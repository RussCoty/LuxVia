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
    private var currentSlide: SlideItem? // Track current slide
    private var displayTimer: Timer?
    private var isPlaying: Bool = false
    
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
        setupBackgroundObservers()
    }
    
    private func setupBackgroundObservers() {
        // Monitor app lifecycle to keep slideshow running
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        guard isPlaying else { return }
        
        print("📱 App entering background - maintaining slideshow on external display")
        
        // NOTE: We no longer use beginBackgroundTask because the silent audio player
        // in AirPlaySlideshowViewController keeps the app alive using the 'audio' background mode.
        // This allows unlimited background execution time, similar to YouTube and Prime Video.
        
        print("✅ Slideshow will continue on external display")
        print("💡 Background audio keeps app active for slideshow playback")
    }
    
    @objc private func appWillEnterForeground() {
        print("📱 App returning to foreground")
        
        if isPlaying {
            print("✅ Slideshow still active - continuing playback")
        }
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
        print("\n🎬 ========================================")
        print("🎬 STARTING SLIDESHOW")
        print("🎬 ========================================")
        
        guard !playlist.slides.isEmpty else {
            print("⚠️ Cannot start slideshow: no slides in playlist")
            return
        }
        
        print("✅ Playlist: \(playlist.name)")
        print("✅ Slides count: \(playlist.slides.count)")
        
        // Check screens BEFORE stopping
        print("\n📺 Screen status BEFORE setup:")
        print("   - Total screens: \(UIScreen.screens.count)")
        for (i, screen) in UIScreen.screens.enumerated() {
            print("   - Screen \(i): \(screen.bounds.size), main: \(screen == UIScreen.main)")
        }
        
        stopSlideshow()
        
        currentPlaylist = playlist
        currentSlideIndex = 0
        isPlaying = true
        
        print("\n🎯 Configuring external display manager...")
        ExternalDisplayManager.shared.configure(with: self)
        
        print("\n🎯 About to display first slide...")
        displayCurrentSlide()
        
        NotificationCenter.default.post(name: SlideshowManager.slideshowDidStart, object: nil)
        print("🎬 ========================================\n")
    }
    
    func stopSlideshow() {
        displayTimer?.invalidate()
        displayTimer = nil
        isPlaying = false
        currentPlaylist = nil
        currentSlideIndex = 0
        currentSlide = nil
        
        // Reset external display manager
        ExternalDisplayManager.shared.reset()
        
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
              currentSlideIndex < playlist.slides.count else {
            print("⚠️ Cannot display slide - invalid index or no playlist")
            if currentPlaylist == nil {
                print("   - currentPlaylist is nil")
            } else if let playlist = currentPlaylist {
                print("   - currentSlideIndex: \(currentSlideIndex), slides.count: \(playlist.slides.count)")
            }
            return
        }
        
        let slide = playlist.slides[currentSlideIndex]
        currentSlide = slide
        
        print("🖼️ Displaying slide \(currentSlideIndex + 1)/\(playlist.slides.count): \(slide.fileName)")
        print("   - Slide type: \(slide.type)")
        print("   - Slide duration: \(slide.duration)s")
        
        // Update the external display via ExternalDisplayManager
        ExternalDisplayManager.shared.displaySlide(slide)
        
        // Notify observers
        NotificationCenter.default.post(
            name: SlideshowManager.slideshowDidUpdateSlide,
            object: nil,
            userInfo: ["slide": slide, "index": currentSlideIndex]
        )
        
        // Schedule next slide (for images, videos handle themselves)
        if slide.type == .image {
            displayTimer?.invalidate()
            let timer = Timer.scheduledTimer(withTimeInterval: slide.duration, repeats: false) { [weak self] _ in
                self?.nextSlide()
            }
            // Add tolerance for better background execution
            timer.tolerance = 0.5
            displayTimer = timer
            
            // Ensure timer runs in common modes (includes during scrolling and background)
            RunLoop.current.add(timer, forMode: .common)
        }
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
    
    func getCurrentSlide() -> SlideItem? {
        return currentSlide
    }
}
