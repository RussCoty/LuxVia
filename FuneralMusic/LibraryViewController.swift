import UIKit
import AVFoundation

class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    let playerControls = PlayerControlsView()

    var tracks: [String] = []
    var isUsingPlaylist = false
    var currentTrackIndex: Int = 0
    var progressTimer: Timer?
    var fadeTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music Library"

        loadTrackList()
        setupUI()
        setupCallbacks()
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
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        playerControls.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(playerControls)

        NSLayoutConstraint.activate([
            playerControls.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerControls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerControls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: playerControls.topAnchor)
        ])
    }

    func setupCallbacks() {
        playerControls.onPlayPause = { [weak self] in self?.togglePlayPause() }
        playerControls.onPrevious = { [weak self] in self?.playPreviousTrack() }
        playerControls.onNext = { [weak self] in self?.playNextTrack() }
        playerControls.onVolumeChange = { value in
            AudioPlayerManager.shared.volume = value
        }
        playerControls.onScrubProgress = { [weak self] value in
            AudioPlayerManager.shared.seek(to: TimeInterval(value))
            self?.updateTimeLabel()
        }
        playerControls.onFadeOut = { [weak self] in self?.fadeOutMusic() }
        playerControls.onPlayPlaylist = { [weak self] in self?.playPlaylist() }
    }

    @objc func togglePlayPause() {
        if AudioPlayerManager.shared.isPlaying {
            AudioPlayerManager.shared.pause()
            playerControls.updatePlayButton(isPlaying: false)
            progressTimer?.invalidate()
        } else {
            AudioPlayerManager.shared.resume()
            playerControls.updatePlayButton(isPlaying: true)
            startProgressTimer()
        }
    }

    func playPreviousTrack() {
        if isUsingPlaylist {
            currentTrackIndex = max(0, currentTrackIndex - 1)
            play(trackNamed: SharedPlaylistManager.shared.playlist[currentTrackIndex])
        } else {
            currentTrackIndex = max(0, currentTrackIndex - 1)
            play(trackNamed: tracks[currentTrackIndex])
        }
    }

    func playNextTrack() {
        if isUsingPlaylist {
            currentTrackIndex = min(SharedPlaylistManager.shared.playlist.count - 1, currentTrackIndex + 1)
            play(trackNamed: SharedPlaylistManager.shared.playlist[currentTrackIndex])
        } else {
            currentTrackIndex = min(tracks.count - 1, currentTrackIndex + 1)
            play(trackNamed: tracks[currentTrackIndex])
        }
    }

    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let player = AudioPlayerManager.shared
            self.playerControls.updateProgress(current: Float(player.currentTime))
            self.playerControls.setMaxProgress(Float(player.duration))
            self.updateTimeLabel()
        }
    }

    func updateTimeLabel() {
        let player = AudioPlayerManager.shared
        let current = Int(player.currentTime)
        let duration = Int(player.duration)
        playerControls.updateTimeLabel(current: current, duration: duration)
    }

    func play(trackNamed name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") else { return }

        AudioPlayerManager.shared.play(url: url)

        playerControls.updatePlayButton(isPlaying: true)
        playerControls.nowPlayingText("Now Playing: \(name.replacingOccurrences(of: "_", with: " ").capitalized)")
        playerControls.setMaxProgress(Float(AudioPlayerManager.shared.duration))
        startProgressTimer()

        if isUsingPlaylist {
            currentTrackIndex = SharedPlaylistManager.shared.playlist.firstIndex(of: name) ?? 0
        } else {
            currentTrackIndex = tracks.firstIndex(of: name) ?? 0
        }
    }

    func fadeOutMusic() {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            let currentVolume = AudioPlayerManager.shared.volume
            if currentVolume > 0.01 {
                AudioPlayerManager.shared.volume = currentVolume - 0.01
            } else {
                AudioPlayerManager.shared.stop()
                AudioPlayerManager.shared.volume = self.playerControls.currentVolume
                self.progressTimer?.invalidate()
                self.playerControls.updatePlayButton(isPlaying: false)
                self.playerControls.nowPlayingText("Now Playing: —")
                self.playerControls.updateProgress(current: 0)
                timer.invalidate()
            }
        }
    }

    func playPlaylist() {
        guard !SharedPlaylistManager.shared.playlist.isEmpty else { return }
        isUsingPlaylist = true
        currentTrackIndex = 0
        play(trackNamed: SharedPlaylistManager.shared.playlist[currentTrackIndex])
    }

    // MARK: - TableView

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
            if !SharedPlaylistManager.shared.playlist.contains(selectedTrack) {
                SharedPlaylistManager.shared.playlist.append(selectedTrack)
                print("Added to playlist: \(selectedTrack)")
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
}
