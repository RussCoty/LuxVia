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
        currentSlide = nil
        
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
        
        // Ensure external display is set up
        if slideshowViewController == nil {
            print("⚠️ Slideshow view controller not initialized, setting up display...")
            setupExternalDisplay()
        }
        
        // Check window status
        if let window = externalWindow {
            print("   - External window exists, isHidden: \(window.isHidden)")
            print("   - Window screen: \(window.screen == UIScreen.main ? "main" : "external")")
        } else {
            print("   - ⚠️ External window is nil!")
        }
        
        // Update the external display
        if let vc = slideshowViewController {
            print("   - View controller exists, sending slide...")
            vc.displaySlide(slide)
            print("✅ Slide sent to external display")
        } else {
            print("❌ Failed to display slide - no view controller")
            print("   - Will retry setup on next slide or external display connection")
        }
        
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
        print("🖥️ External display connected notification received")
        if let screen = notification.object as? UIScreen {
            print("🖥️ Screen details: \(screen.bounds)")
        }
        
        // Always try to set up or refresh the display when connected
        if isPlaying {
            print("🖥️ Slideshow is playing, setting up display...")
            setupExternalDisplay()
            
            // Re-display current slide if we have one
            if let slide = currentSlide {
                slideshowViewController?.displaySlide(slide)
            }
        } else {
            print("🖥️ Slideshow not playing, display ready for next start")
        }
    }
    
    @objc private func externalDisplayDidDisconnect(notification: Notification) {
        print("🖥️ External display disconnected")
        teardownExternalDisplay()
    }
    
    private func setupExternalDisplay() {
        print("🖥️ Attempting to setup external display...")
        print("🖥️ Available screens: \(UIScreen.screens.count)")
        
        // List all screens for debugging
        for (index, screen) in UIScreen.screens.enumerated() {
            print("🖥️ Screen \(index): \(screen.bounds), main: \(screen == UIScreen.main)")
        }
        
        // Check if there's an external screen available
        guard let externalScreen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else {
            print("⚠️ No external display found")
            print("⚠️ Please connect to AirPlay first, then start the slideshow")
            print("⚠️ The slideshow will display once AirPlay is connected")
            
            // Don't set up on main screen - wait for external display
            // The didConnect notification will trigger setup when AirPlay connects
            return
        }
        
        print("✅ External display found: \(externalScreen.bounds)")
        setupDisplayWindow(on: externalScreen)
    }
    
    private func setupDisplayWindow(on screen: UIScreen) {
        print("🖥️ Setting up display window on screen: \(screen == UIScreen.main ? "main" : "external")")
        print("🖥️ Screen bounds: \(screen.bounds)")
        
        // Clean up any existing window
        teardownExternalDisplay()
        
        // Create window for the display
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.backgroundColor = .black
        window.windowLevel = UIWindow.Level.normal + 1
        
        // Create and set the slideshow view controller
        let slideshowVC = AirPlaySlideshowViewController()
        window.rootViewController = slideshowVC
        
        // Force the view to load
        slideshowVC.loadViewIfNeeded()
        
        // Store references BEFORE making visible
        externalWindow = window
        slideshowViewController = slideshowVC
        
        // Make window key and visible - CRITICAL for external displays
        window.makeKeyAndVisible()
        window.isHidden = false
        
        // Additional visibility check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.isHidden = false
            print("✅ Window visibility re-confirmed")
        }
        
        print("✅ Window created and made visible")
        print("✅ Window screen: \(window.screen.bounds)")
        print("✅ Window frame: \(window.frame)")
        print("✅ Window isHidden: \(window.isHidden)")
        print("✅ Window isKeyWindow: \(window.isKeyWindow)")
        print("✅ View controller loaded: \(slideshowVC.isViewLoaded)")
        print("✅ View controller view frame: \(slideshowVC.view.frame)")
        
        // If we have a current slide, display it immediately
        if let slide = currentSlide {
            print("🖼️ Displaying current slide: \(slide.fileName)")
            slideshowVC.displaySlide(slide)
        } else {
            print("⚠️ No current slide to display yet")
        }
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
    
    func getCurrentSlide() -> SlideItem? {
        return currentSlide
    }
}
