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
    
    // MARK: - Constants
    private enum Constants {
        static let screenReadyDelay: TimeInterval = 0.3
        static let slideDisplayDelay: TimeInterval = 0.2
    }
    
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
        
        // Check if external screen is already connected before linear search
        guard UIScreen.screens.count > 1,
              let externalScreen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else {
            return
        }
        
        setupDisplayWindow(on: externalScreen)
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
        guard let screen = notification.object as? UIScreen else {
            print("⚠️ ExternalDisplayManager: screenDidConnect called but no screen in notification")
            return
        }
        
        // Only handle external screens, not the main screen
        guard screen != UIScreen.main else {
            print("🖥️ ExternalDisplayManager: Ignoring main screen connection")
            return
        }
        
        print("🖥️ ExternalDisplayManager: External screen connected")
        print("   - Screen bounds: \(screen.bounds)")
        print("   - slideshowModel configured: \(slideshowModel != nil)")
        
        // Small delay to ensure screen is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.screenReadyDelay) { [weak self] in
            print("🖥️ ExternalDisplayManager: Calling setupDisplayWindow after delay...")
            self?.setupDisplayWindow(on: screen)
            
            // If slideshow is active, display current slide
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.slideDisplayDelay) { [weak self] in
                if let slide = self?.slideshowModel?.getCurrentSlide() {
                    print("🔄 Displaying current slide on newly connected display")
                    self?.slideshowViewController?.displaySlide(slide)
                } else {
                    print("ℹ️ No current slide to display (slideshow may not be started yet)")
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
        // Double-check we're not setting up on the main screen
        guard screen != UIScreen.main else {
            print("⚠️ ExternalDisplayManager: Attempted to setup on main screen - aborting")
            return
        }
        
        print("🖥️ ExternalDisplayManager: Setting up display window on external screen")
        print("   - Screen bounds: \(screen.bounds)")
        
        // Clean up any existing window
        teardownExternalDisplay()
        
        // Request a new UIWindowScene for the external display
        let sceneSessionOptions = UIWindowScene.ActivationRequestOptions()
        sceneSessionOptions.requestingScene = nil
        
        UIApplication.shared.requestSceneSessionActivation(
            nil,
            userActivity: nil,
            options: sceneSessionOptions
        ) { _ in
            // Error handler - scene activation errors are logged by system
        }
        
        // Find or wait for the external window scene
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupWindowWithScene(for: screen)
        }
    }
    
    private func setupWindowWithScene(for screen: UIScreen) {
        // Find the window scene for the external screen
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.screen == screen }) else {
            print("⚠️ ExternalDisplayManager: No window scene found for external screen")
            // Fallback to old method for compatibility
            setupWindowLegacy(on: screen)
            return
        }
        
        print("🖥️ ExternalDisplayManager: Found window scene for external screen")
        
        // Create window for the external display using the scene
        let window = UIWindow(windowScene: windowScene)
        window.frame = screen.bounds
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
        
        // Make window visible on external screen
        // Important: We show the window but DON'T make it key to avoid stealing focus from main window
        window.isHidden = false
        
        // Force layout and redraw
        window.setNeedsLayout()
        window.layoutIfNeeded()
        window.setNeedsDisplay()
        
        print("✅ ExternalDisplayManager: Window created and configured with UIWindowScene")
        print("   - Window frame: \(window.frame)")
        print("   - Window isHidden: \(window.isHidden)")
        print("   - Window isKeyWindow: \(window.isKeyWindow)")
        
        // Display current slide if available
        if let slide = slideshowModel?.getCurrentSlide() {
            print("🖼️ Displaying current slide on setup: \(slide.fileName)")
            slideshowVC.displaySlide(slide)
        } else {
            print("ℹ️ No current slide available on setup (waiting for slideshow to start)")
        }
    }
    
    private func setupWindowLegacy(on screen: UIScreen) {
        print("🖥️ ExternalDisplayManager: Using legacy window setup (pre-iOS 13)")
        
        // Create window for the external display using legacy API
        let window = UIWindow(frame: screen.bounds)
        // Note: Using deprecated window.screen setter for iOS 12 compatibility
        // This is intentional - UIWindowScene should be used for iOS 13+, but may not always be available
        // The deprecation warning can be ignored as this is a necessary fallback
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
        
        // Make window visible on external screen
        window.isHidden = false
        
        // Force layout and redraw
        window.setNeedsLayout()
        window.layoutIfNeeded()
        window.setNeedsDisplay()
        
        print("✅ ExternalDisplayManager: Window created with legacy API")
        print("   - Window frame: \(window.frame)")
        print("   - Window isHidden: \(window.isHidden)")
        
        // Display current slide if available
        if let slide = slideshowModel?.getCurrentSlide() {
            print("🖼️ Displaying current slide on setup: \(slide.fileName)")
            slideshowVC.displaySlide(slide)
        } else {
            print("ℹ️ No current slide available on setup (waiting for slideshow to start)")
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
