//
//  ExternalDisplayManager.swift
//  LuxVia
//
//  Created on 11/12/2024.
//

import UIKit
import Foundation

/// Manages external display (AirPlay/Screen Mirroring) windows for slideshow presentation.
/// This manager handles UIScreen connections and displays slideshow content on external displays.
final class ExternalDisplayManager {
    static let shared = ExternalDisplayManager()
    
    // MARK: - Properties
    private var externalWindow: UIWindow?
    private var slideshowViewController: AirPlaySlideshowViewController?
    private weak var slideshowModel: SlideshowManagerProtocol?
    
    // MARK: - Initialization
    private init() {
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configuration
    
    /// Configure the external display manager with a slideshow model.
    /// Call this when entering the "Manage slideshow images" screen with an active playlist.
    /// - Parameter slideshowModel: The slideshow manager instance driving the presentation
    func configure(with slideshowModel: SlideshowManagerProtocol) {
        self.slideshowModel = slideshowModel
        
        // If an external screen is already connected, set it up immediately
        if let externalScreen = UIScreen.screens.first(where: { $0 != UIScreen.main }) {
            setupDisplayWindow(on: externalScreen)
        }
    }
    
    /// Clear the current configuration and tear down any external displays
    func reset() {
        teardownExternalDisplay()
        slideshowModel = nil
    }
    
    // MARK: - External Screen Observers
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidConnect(_:)),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidDisconnect(_:)),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }
    
    @objc private func screenDidConnect(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }
        
        print("🖥️ ExternalDisplayManager: Screen connected")
        print("   - Screen bounds: \(screen.bounds)")
        print("   - Is main screen: \(screen == UIScreen.main)")
        
        // Small delay to ensure screen is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.setupDisplayWindow(on: screen)
            
            // If slideshow is active, display current slide
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                if let slide = self?.slideshowModel?.getCurrentSlide() {
                    print("🔄 Displaying current slide on newly connected display")
                    self?.slideshowViewController?.displaySlide(slide)
                }
            }
        }
    }
    
    @objc private func screenDidDisconnect(_ notification: Notification) {
        print("🖥️ ExternalDisplayManager: Screen disconnected")
        teardownExternalDisplay()
    }
    
    // MARK: - Display Window Management
    
    private func setupDisplayWindow(on screen: UIScreen) {
        print("🖥️ ExternalDisplayManager: Setting up display window")
        print("   - Screen bounds: \(screen.bounds)")
        
        // Clean up any existing window
        teardownExternalDisplay()
        
        // Create window for the external display
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.backgroundColor = .black
        window.windowLevel = UIWindow.Level.normal + 1
        window.isOpaque = true
        
        // Create slideshow view controller
        let slideshowVC = AirPlaySlideshowViewController()
        window.rootViewController = slideshowVC
        
        // Force view to load and layout
        slideshowVC.loadViewIfNeeded()
        slideshowVC.view.frame = window.bounds
        slideshowVC.view.setNeedsLayout()
        slideshowVC.view.layoutIfNeeded()
        
        // Ensure visibility
        slideshowVC.view.isHidden = false
        slideshowVC.view.alpha = 1.0
        
        // Store references
        externalWindow = window
        slideshowViewController = slideshowVC
        
        // Make window visible - critical for external displays
        window.isHidden = false
        window.makeKey()
        
        // Force layout and redraw
        window.setNeedsLayout()
        window.layoutIfNeeded()
        window.setNeedsDisplay()
        
        print("✅ ExternalDisplayManager: Window created and configured")
        print("   - Window frame: \(window.frame)")
        print("   - Window isHidden: \(window.isHidden)")
        print("   - Window isKeyWindow: \(window.isKeyWindow)")
        
        // Display current slide if available
        if let slide = slideshowModel?.getCurrentSlide() {
            print("🖼️ Displaying current slide: \(slide.fileName)")
            DispatchQueue.main.async {
                slideshowVC.displaySlide(slide)
            }
        }
    }
    
    private func teardownExternalDisplay() {
        print("🧹 ExternalDisplayManager: Tearing down external display")
        externalWindow?.isHidden = true
        externalWindow?.rootViewController = nil
        externalWindow = nil
        slideshowViewController = nil
    }
    
    // MARK: - Public Methods
    
    /// Display a slide on the external display (if connected)
    /// - Parameter slide: The slide to display
    func displaySlide(_ slide: SlideItem) {
        guard let vc = slideshowViewController else {
            print("⚠️ ExternalDisplayManager: No external display available")
            return
        }
        
        vc.displaySlide(slide)
    }
    
    /// Check if an external display is currently connected
    /// - Returns: true if external display is connected and window is active
    func isExternalDisplayConnected() -> Bool {
        return externalWindow != nil && UIScreen.screens.count > 1
    }
}

/// Protocol to abstract SlideshowManager for ExternalDisplayManager
protocol SlideshowManagerProtocol: AnyObject {
    func getCurrentSlide() -> SlideItem?
}

/// Extension to make SlideshowManager conform to the protocol
extension SlideshowManager: SlideshowManagerProtocol {}
