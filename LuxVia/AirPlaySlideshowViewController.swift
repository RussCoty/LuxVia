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
    
    // MARK: - Background Audio Support
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupImageView()
        setupBackgroundAudio()
        
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
        
        // Ensure view is visible FIRST
        view.isHidden = false
        view.alpha = 1.0
        imageView.isHidden = false
        imageView.alpha = 1.0
        
        // Force a full layout and display update
        view.setNeedsLayout()
        view.layoutIfNeeded()
        view.setNeedsDisplay()
        imageView.setNeedsLayout()
        imageView.layoutIfNeeded()
        imageView.setNeedsDisplay()
        
        // Force render immediately
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        view.layer.setNeedsDisplay()
        imageView.layer.setNeedsDisplay()
        view.layer.displayIfNeeded()
        imageView.layer.displayIfNeeded()
        CATransaction.commit()
        
        // If there's already an image, make sure it's showing
        if let image = imageView.image {
            print("   - ✅ Image present: \(image.size)")
            // Force immediate redisplay of the image
            imageView.image = nil
            imageView.image = image
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
    
    private func setupBackgroundAudio() {
        // Configure audio session to allow background playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use .playback category without mixing to ensure background execution
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("✅ Audio session configured for background playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
        
        // Create a silent audio player to keep app alive in background
        // We'll use an AVAudioPlayerNode with AVAudioEngine for simplicity
        startSilentAudioEngine()
    }
    
    private func startSilentAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Create a silent buffer (1 second of silence)
        let sampleRate = 44100.0
        let bufferSize = AVAudioFrameCount(sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
            print("❌ Failed to create audio buffer")
            return
        }
        buffer.frameLength = bufferSize
        
        // Fill with silence (zeros) - this is already the default
        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(bufferSize) {
                data[i] = 0.0
            }
        }
        
        do {
            try engine.start()
            
            // Schedule buffer in a loop
            player.play()
            scheduleBuffer(buffer)
            
            print("✅ Silent audio engine started for background playback")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    private func scheduleBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let player = playerNode else { return }
        player.scheduleBuffer(buffer, at: nil, options: .loops)
    }
    
    private func stopBackgroundAudio() {
        playerNode?.stop()
        audioEngine?.stop()
        playerNode = nil
        audioEngine = nil
        print("🛑 Background audio stopped")
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }
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
            
            // Force IMMEDIATE display update using CATransaction
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.imageView.layer.setNeedsDisplay()
            self.view.layer.setNeedsDisplay()
            self.imageView.layer.displayIfNeeded()
            self.view.layer.displayIfNeeded()
            CATransaction.commit()
            
            // Also use standard update methods
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
        stopBackgroundAudio()
        NotificationCenter.default.removeObserver(self)
    }
}
