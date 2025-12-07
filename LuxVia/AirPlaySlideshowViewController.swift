//
//  AirPlaySlideshowViewController.swift
//  LuxVia
//
//  Created on 16/11/2025.
//

import UIKit
import AVFoundation
import AVKit

/// This view controller displays on the external AirPlay screen
class AirPlaySlideshowViewController: UIViewController {
    
    // MARK: - UI Components
    private let imageView = UIImageView()
    private var playerViewController: AVPlayerViewController?
    private var currentPlayer: AVPlayer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupImageView()
        
        print("📺 AirPlaySlideshowViewController viewDidLoad")
        print("   - View bounds: \(view.bounds)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📺 AirPlaySlideshowViewController viewDidAppear")
        print("   - View frame: \(view.frame)")
        print("   - ImageView frame: \(imageView.frame)")
        print("   - View is in window: \(view.window != nil)")
        print("   - Window bounds: \(view.window?.bounds ?? .zero)")
        print("   - View background: \(view.backgroundColor?.description ?? "nil")")
        
        // Force a full layout and display update
        view.setNeedsLayout()
        view.layoutIfNeeded()
        view.setNeedsDisplay()
        imageView.setNeedsDisplay()
        
        // Ensure view is visible
        view.isHidden = false
        view.alpha = 1.0
        
        // If there's already an image, make sure it's showing
        if let image = imageView.image {
            print("   - ✅ Image present: \(image.size)")
            // Force redisplay of the image
            imageView.setNeedsDisplay()
            view.setNeedsDisplay()
        } else {
            print("   - ⚠️ No image currently displayed")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure imageView maintains correct frame after layout
        if imageView.frame != view.bounds {
            print("🔄 Layout mismatch detected, updating imageView frame")
            print("   - View bounds: \(view.bounds)")
            print("   - ImageView frame: \(imageView.frame)")
        }
    }
    
    // MARK: - Setup
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Display Slide
    func displaySlide(_ slide: SlideItem) {
        print("📺 AirPlaySlideshowViewController: Displaying slide \(slide.fileName)")
        print("   - View is in window: \(view.window != nil)")
        print("   - View is hidden: \(view.isHidden)")
        print("   - View alpha: \(view.alpha)")
        
        let fileURL = SlideshowManager.shared.getMediaURL(for: slide.fileName)
        
        // Verify file exists
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("❌ File does not exist at: \(fileURL.path)")
            return
        }
        
        print("✅ File exists, type: \(slide.type)")
        
        // Ensure view is visible before displaying content
        view.isHidden = false
        view.alpha = 1.0
        
        switch slide.type {
        case .image:
            displayImage(from: fileURL)
        case .video:
            displayVideo(from: fileURL)
        }
    }
    
    private func displayImage(from url: URL) {
        print("🖼️ Loading image from: \(url.path)")
        
        // Stop any playing video
        stopVideo()
        
        // Load and display image
        if let image = UIImage(contentsOfFile: url.path) {
            print("✅ Image loaded successfully")
            print("   - Image size: \(image.size)")
            print("   - View bounds: \(self.view.bounds)")
            print("   - ImageView frame before: \(imageView.frame)")
            
            // Make sure everything is visible
            self.view.isHidden = false
            self.view.alpha = 1.0
            imageView.isHidden = false
            imageView.alpha = 1.0
            imageView.backgroundColor = .black
            
            // Force layout before setting image
            view.setNeedsLayout()
            view.layoutIfNeeded()
            imageView.setNeedsLayout()
            imageView.layoutIfNeeded()
            
            print("   - ImageView frame after layout: \(imageView.frame)")
            
            // Set the image directly first (no animation for initial display)
            self.imageView.image = image
            
            // Force display update immediately
            self.imageView.setNeedsDisplay()
            self.view.setNeedsDisplay()
            
            print("✅ Image set on imageView")
            print("   - ImageView has image: \(self.imageView.image != nil)")
            print("   - ImageView frame: \(self.imageView.frame)")
            print("   - ImageView bounds: \(self.imageView.bounds)")
            print("   - ImageView is hidden: \(self.imageView.isHidden)")
            print("   - ImageView alpha: \(self.imageView.alpha)")
            print("   - ImageView superview: \(self.imageView.superview != nil)")
            print("   - View window: \(self.view.window != nil)")
            
            // Final layout update
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        } else {
            print("❌ Failed to load image from: \(url.path)")
            print("❌ File exists: \(FileManager.default.fileExists(atPath: url.path))")
        }
    }
    
    private func displayVideo(from url: URL) {
        print("🎬 Loading video from: \(url.path)")
        
        // Hide image view
        imageView.isHidden = true
        
        // Stop any existing video
        stopVideo()
        
        // Create player
        let player = AVPlayer(url: url)
        currentPlayer = player
        
        // Create player view controller
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.showsPlaybackControls = false
        playerVC.videoGravity = .resizeAspect
        playerViewController = playerVC
        
        // Add player to view hierarchy
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.view.frame = view.bounds
        playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerVC.didMove(toParent: self)
        
        // Play video
        player.play()
        print("✅ Video player started")
        
        // Observe when video ends to notify manager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }
    
    private func stopVideo() {
        currentPlayer?.pause()
        currentPlayer = nil
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil
    }
    
    @objc private func videoDidEnd() {
        // Notify manager to move to next slide
        SlideshowManager.shared.nextSlide()
    }
    
    deinit {
        stopVideo()
        NotificationCenter.default.removeObserver(self)
    }
}
