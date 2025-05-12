//
//  PlaylistViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//

import UIKit
import AVFoundation

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    let playButton = UIButton(type: .system)
    var audioPlayer: AVAudioPlayer?
    var currentTrackIndex = 0
    var progressTimer: Timer?

    // This should be the same shared playlist as in LibraryViewController
    var playlist: [String] {
        get {
            return SharedPlaylistManager.shared.tracks
        }
        set {
            SharedPlaylistManager.shared.tracks = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Playlist"

        setupUI()
    }

    func setupUI() {
        // Table View
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setEditing(true, animated: false)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Play Playlist Button
        playButton.setTitle("Play Playlist", for: .normal)
        playButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        playButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        playButton.layer.cornerRadius = 8
        playButton.setTitleColor(.black, for: .normal)
        playButton.addTarget(self, action: #selector(playPlaylist), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playButton)

        // Layout
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            playButton.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: playButton.topAnchor, constant: -10)
        ])
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "PlaylistCell")
        cell.textLabel?.text = playlist[indexPath.row].capitalized
        return cell
    }

    // Enable reordering
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedTrack = playlist.remove(at: sourceIndexPath.row)
        playlist.insert(movedTrack, at: destinationIndexPath.row)
    }

    @objc func playPlaylist() {
        guard !playlist.isEmpty else { return }
        currentTrackIndex = 0
        play(trackNamed: playlist[currentTrackIndex])
    }

    func play(trackNamed name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") else {
            print("Track not found in Audio folder: \(name)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            startProgressTimer()
        } catch {
            print("Playback failed: \(error)")
        }
    }

    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let player = self.audioPlayer,
                  player.currentTime >= player.duration else { return }

            self.progressTimer?.invalidate()
            self.playNext()
        }
    }

    func playNext() {
        currentTrackIndex += 1
        if currentTrackIndex < playlist.count {
            play(trackNamed: playlist[currentTrackIndex])
        }
    }
}

// Shared playlist manager to keep the playlist in sync between view controllers
class SharedPlaylistManager {
    static let shared = SharedPlaylistManager()
    private init() {}

    var tracks: [String] = []
}

