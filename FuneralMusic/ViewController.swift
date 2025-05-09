//
//  ViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//

import UIKit
import WebKit
import AVFoundation

class ViewController: UIViewController {
    
    var webView: WKWebView!
    // var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Inject CSS to shrink the header for in-app view
        let customCSS = """
        .custom-header-media {
          //  max-height: 60px !important;
          //  overflow: hidden !important;
        }
        """

        let scriptSource = "var style = document.createElement('style'); style.innerHTML = `\(customCSS)`; document.head.appendChild(style);"
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let contentController = WKUserContentController()
        contentController.addUserScript(script)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        // Set up WebView with custom configuration
        webView = WKWebView(frame: self.view.bounds, configuration: config)
        webView.customUserAgent = "FuneralMusicApp" // Optional: Helps WordPress detect the app
        view.addSubview(webView)

        if let url = URL(string: "https://funeralmusic.co.uk/how-it-works-130/") {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        /*
        // Add Play Button (floating)
        let playButton = UIButton(type: .system)
        playButton.setTitle("Play Song", for: .normal)
        playButton.backgroundColor = UIColor.systemBlue
        playButton.tintColor = .white
        playButton.layer.cornerRadius = 10
        playButton.frame = CGRect(x: 20, y: self.view.bounds.height - 80, width: 120, height: 44)
        playButton.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
        playButton.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
        view.addSubview(playButton)
        */
    }

    /*
    @objc func playAudio() {
        guard let fileURL = Bundle.main.url(forResource: "funeral_music_sample", withExtension: "mp3") else {
            print("Audio file not found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error loading audio player: \(error)")
        }
    }
     */
}

