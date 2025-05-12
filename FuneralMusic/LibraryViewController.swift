//  LibraryViewController.swift
//  FuneralMusic

import UIKit
import AVFoundation

class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    let nowPlayingLabel = UILabel()
    let playPauseButton = UIButton(type: .system)
    let nextButton = UIButton(type: .system)
    let prevButton = UIButton(type: .system)
    let volumeSlider = UISlider()
    let progressSlider = UISlider()
    let timeLabel = UILabel()
    var fadeTimer: Timer?

    var tracks: [String] = []
    var playlist: [String] = []
    var isUsingPlaylist = false
    var currentTrackIndex: Int = 0
    var audioPlayer: AVAudioPlayer?
    var progressTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music Library"

        loadTrackList()
        setupUI()
    }

    func loadTrackList() {
        if let audioFolderURL = Bundle.main.resourceURL?.appendingPathComponent("Audio") {
            let allFiles = try? FileManager.default.contentsOfDirectory(at: audioFolderURL, includingPropertiesForKeys: nil)
            self.tracks = allFiles?
                .filter { $0.pathExtension.lowercased() == "mp3" }
                .map { $0.deletingPathExtension().lastPathComponent } ?? []
        }
    }

    func setupUI() {
        nowPlayingLabel.text = "Now Playing: —"
        nowPlayingLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nowPlayingLabel.textAlignment = .center

        playPauseButton.setImage(UIImage(named: "button_play"), for: .normal)
        prevButton.setImage(UIImage(named: "button_prev"), for: .normal)
        nextButton.setImage(UIImage(named: "button_next"), for: .normal)

        [playPauseButton, prevButton, nextButton].forEach {
            $0.setTitle("", for: .normal)
            $0.tintColor = .black
            $0.imageView?.contentMode = .scaleAspectFit
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 64).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 64).isActive = true
        }

        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        prevButton.addTarget(self, action: #selector(playPreviousTrack), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(playNextTrack), for: .touchUpInside)

        volumeSlider.value = 0.5
        volumeSlider.tintColor = UIColor.gray
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)

        progressSlider.minimumValue = 0
        progressSlider.tintColor = UIColor.gray
        progressSlider.addTarget(self, action: #selector(scrubProgress), for: .valueChanged)

        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.textAlignment = .center
        timeLabel.text = "0:00 / 0:00"

        let buttonStack = UIStackView(arrangedSubviews: [prevButton, playPauseButton, nextButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .equalSpacing

        let fadeButton = UIButton(type: .system)
        fadeButton.setTitle("Fade Out", for: .normal)
        fadeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        fadeButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        fadeButton.layer.cornerRadius = 8
        fadeButton.setTitleColor(.black, for: .normal)
        fadeButton.addTarget(self, action: #selector(fadeOutMusic), for: .touchUpInside)

        let playlistButton = UIButton(type: .system)
        playlistButton.setTitle("Play Playlist", for: .normal)
        playlistButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        playlistButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        playlistButton.layer.cornerRadius = 8
        playlistButton.setTitleColor(.black, for: .normal)
        playlistButton.addTarget(self, action: #selector(playPlaylist), for: .touchUpInside)

        let controlsStack = UIStackView(arrangedSubviews: [nowPlayingLabel, progressSlider, timeLabel, buttonStack, volumeSlider, fadeButton, playlistButton])
        controlsStack.axis = .vertical
        controlsStack.spacing = 10
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(controlsStack)

        NSLayoutConstraint.activate([
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: controlsStack.topAnchor, constant: -10)
        ])
    }

    @objc func togglePlayPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            playPauseButton.setImage(UIImage(named: "button_play"), for: .normal)
            progressTimer?.invalidate()
        } else {
            player.play()
            playPauseButton.setImage(UIImage(named: "button_pause"), for: .normal)
            startProgressTimer()
        }
    }

    @objc func playPreviousTrack() {
        if isUsingPlaylist {
            currentTrackIndex = max(0, currentTrackIndex - 1)
            play(trackNamed: playlist[currentTrackIndex])
        } else {
            currentTrackIndex = max(0, currentTrackIndex - 1)
            play(trackNamed: tracks[currentTrackIndex])
        }
    }

    @objc func playNextTrack() {
        if isUsingPlaylist {
            currentTrackIndex = min(playlist.count - 1, currentTrackIndex + 1)
            play(trackNamed: playlist[currentTrackIndex])
        } else {
            currentTrackIndex = min(tracks.count - 1, currentTrackIndex + 1)
            play(trackNamed: tracks[currentTrackIndex])
        }
    }

    @objc func volumeChanged() {
        audioPlayer?.volume = volumeSlider.value
    }

    @objc func scrubProgress() {
        guard let player = audioPlayer else { return }
        player.currentTime = TimeInterval(progressSlider.value)
        updateTimeLabel()
    }

    func play(trackNamed name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = volumeSlider.value
            audioPlayer?.play()
            nowPlayingLabel.text = "Now Playing: \(name.replacingOccurrences(of: "_", with: " ").capitalized)"
            playPauseButton.setImage(UIImage(named: "button_pause"), for: .normal)
            if isUsingPlaylist {
                currentTrackIndex = playlist.firstIndex(of: name) ?? 0
            } else {
                currentTrackIndex = tracks.firstIndex(of: name) ?? 0
            }
            progressSlider.maximumValue = Float(audioPlayer?.duration ?? 1)
            startProgressTimer()
        } catch {
            print("Playback failed: \(error)")
        }
    }

    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let player = self.audioPlayer else { return }
            self.progressSlider.value = Float(player.currentTime)
            self.updateTimeLabel()
        }
    }

    func updateTimeLabel() {
        guard let player = audioPlayer else { return }
        let current = Int(player.currentTime)
        let duration = Int(player.duration)
        let currentMin = current / 60, currentSec = current % 60
        let durationMin = duration / 60, durationSec = duration % 60
        timeLabel.text = String(format: "%d:%02d / %d:%02d", currentMin, currentSec, durationMin, durationSec)
    }

    @objc func fadeOutMusic() {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }

            if player.volume > 0.01 {
                player.volume -= 0.01
            } else {
                player.stop()
                player.volume = self.volumeSlider.value
                self.progressTimer?.invalidate()
                self.progressSlider.value = 0
                self.timeLabel.text = "0:00 / 0:00"
                self.playPauseButton.setImage(UIImage(named: "button_play"), for: .normal)
                self.nowPlayingLabel.text = "Now Playing: —"
                timer.invalidate()
            }
        }
    }

    @objc func playPlaylist() {
        guard !playlist.isEmpty else { return }
        isUsingPlaylist = true
        currentTrackIndex = 0
        play(trackNamed: playlist[currentTrackIndex])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "TrackCell")
        cell.textLabel?.text = tracks[indexPath.row].capitalized
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = tracks[indexPath.row]

        let alert = UIAlertController(title: selectedTrack, message: "Choose an action", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Play Now", style: .default) { _ in
            self.isUsingPlaylist = false
            self.play(trackNamed: selectedTrack)
        })

        alert.addAction(UIAlertAction(title: "Add to Playlist", style: .default) { _ in
            if !self.playlist.contains(selectedTrack) {
                self.playlist.append(selectedTrack)
                print("Added to playlist: \(selectedTrack)")
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
}
