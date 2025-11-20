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
        let fileURL = SlideshowManager.shared.getMediaURL(for: slide.fileName)
        
        // Verify file exists
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("❌ File does not exist at: \(fileURL.path)")
            return
        }
        
        print("✅ File exists, type: \(slide.type)")
        
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
            print("✅ Image loaded successfully, size: \(image.size)")
            UIView.transition(with: imageView,
                            duration: 0.5,
                            options: .transitionCrossDissolve,
                            animations: {
                self.imageView.image = image
                self.imageView.isHidden = false
            })
        } else {
            print("❌ Failed to load image from: \(url.path)")
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
