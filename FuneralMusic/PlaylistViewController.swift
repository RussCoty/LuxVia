//  PlaylistViewController.swift
//  FuneralMusic

import UIKit
import AVFoundation

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    let playButton = UIButton(type: .system)

    var audioPlayer: AVAudioPlayer?
    var currentTrackIndex = 0
    var progressTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Playlist"

        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData() // Refresh playlist display when returning to this view
    }

    func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.setEditing(true, animated: false) // Enable drag-to-reorder

        playButton.setTitle("Play Playlist", for: .normal)
        playButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        playButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        playButton.layer.cornerRadius = 8
        playButton.setTitleColor(.black, for: .normal)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playPlaylist), for: .touchUpInside)

        view.addSubview(tableView)
        view.addSubview(playButton)

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

    @objc func playPlaylist() {
        guard !SharedPlaylistManager.shared.playlist.isEmpty else { return }
        currentTrackIndex = 0
        playTrack(at: currentTrackIndex)
    }

    func playTrack(at index: Int) {
        let track = SharedPlaylistManager.shared.playlist[index]
        guard let url = Bundle.main.url(forResource: track, withExtension: "mp3", subdirectory: "Audio") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            startProgressTimer()
        } catch {
            print("Error playing track \(track): \(error)")
        }
    }

    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let player = self.audioPlayer else { return }
            if player.isPlaying == false {
                self.advanceToNextTrack()
            }
        }
    }

    func advanceToNextTrack() {
        currentTrackIndex += 1
        if currentTrackIndex < SharedPlaylistManager.shared.playlist.count {
            playTrack(at: currentTrackIndex)
        } else {
            progressTimer?.invalidate()
            audioPlayer = nil
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedPlaylistManager.shared.playlist.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "PlaylistCell")
        cell.textLabel?.text = SharedPlaylistManager.shared.playlist[indexPath.row].capitalized
        return cell
    }

    // Enable reordering
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var playlist = SharedPlaylistManager.shared.playlist
        let movedItem = playlist.remove(at: sourceIndexPath.row)
        playlist.insert(movedItem, at: destinationIndexPath.row)
        SharedPlaylistManager.shared.playlist = playlist
    }
}
