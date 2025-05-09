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

    var tracks: [String] = []
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
        if let resourcePath = Bundle.main.resourcePath {
            let allFiles = try? FileManager.default.contentsOfDirectory(atPath: resourcePath)
            self.tracks = allFiles?.filter { $0.hasSuffix(".mp3") }.map { $0.replacingOccurrences(of: ".mp3", with: "") } ?? []
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

        let controlsStack = UIStackView(arrangedSubviews: [nowPlayingLabel, progressSlider, timeLabel, buttonStack, volumeSlider])
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
        currentTrackIndex = max(0, currentTrackIndex - 1)
        play(trackNamed: tracks[currentTrackIndex])
    }

    @objc func playNextTrack() {
        currentTrackIndex = min(tracks.count - 1, currentTrackIndex + 1)
        play(trackNamed: tracks[currentTrackIndex])
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
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = volumeSlider.value
            audioPlayer?.play()
            nowPlayingLabel.text = "Now Playing: \(name.replacingOccurrences(of: "_", with: " ").capitalized)"
            playPauseButton.setImage(UIImage(named: "button_pause"), for: .normal)
            currentTrackIndex = tracks.firstIndex(of: name) ?? 0
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "TrackCell")
        cell.textLabel?.text = tracks[indexPath.row].capitalized
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentTrackIndex = indexPath.row
        play(trackNamed: tracks[currentTrackIndex])
    }
}
