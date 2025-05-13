import UIKit
import AVFoundation

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    let playerControls = PlayerControlsView()

    var currentTrackIndex = 0
    var progressTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Playlist"

        setupUI()
        setupCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.setEditing(true, animated: false)

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
            tableView.bottomAnchor.constraint(equalTo: playerControls.topAnchor, constant: -10)
        ])
    }

    func setupCallbacks() {
        playerControls.onPlayPause = { [weak self] in
            guard let self = self else { return }
            if AudioPlayerManager.shared.isPlaying {
                AudioPlayerManager.shared.pause()
                self.playerControls.updatePlayButton(isPlaying: false)
            } else {
                AudioPlayerManager.shared.resume()
                self.playerControls.updatePlayButton(isPlaying: true)
            }
        }

        playerControls.onNext = { [weak self] in
            self?.advanceToNextTrack()
        }

        playerControls.onVolumeChange = { value in
            AudioPlayerManager.shared.volume = value
        }

        playerControls.onScrubProgress = { [weak self] value in
            AudioPlayerManager.shared.seek(to: TimeInterval(value))
            self?.updateTimeLabel()
        }

        playerControls.onPlayPlaylist = { [weak self] in
            guard let self = self else { return }
            guard !SharedPlaylistManager.shared.playlist.isEmpty else { return }
            self.currentTrackIndex = 0
            self.playTrack(at: self.currentTrackIndex)
        }
    }

    func playTrack(at index: Int) {
        let track = SharedPlaylistManager.shared.playlist[index]
        guard let url = Bundle.main.url(forResource: track, withExtension: "mp3", subdirectory: "Audio") else { return }

        AudioPlayerManager.shared.play(url: url)
        playerControls.updatePlayButton(isPlaying: true)
        playerControls.nowPlayingText("Now Playing: \(track.replacingOccurrences(of: "_", with: " ").capitalized)")
        playerControls.setMaxProgress(Float(AudioPlayerManager.shared.duration))

        startProgressTimer()
    }

    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if !AudioPlayerManager.shared.isPlaying {
                self.advanceToNextTrack()
            }

            self.playerControls.updateProgress(current: Float(AudioPlayerManager.shared.currentTime))
            self.playerControls.setMaxProgress(Float(AudioPlayerManager.shared.duration))
            self.updateTimeLabel()
        }
    }

    func advanceToNextTrack() {
        currentTrackIndex += 1
        if currentTrackIndex < SharedPlaylistManager.shared.playlist.count {
            playTrack(at: currentTrackIndex)
        } else {
            progressTimer?.invalidate()
            AudioPlayerManager.shared.stop()
            playerControls.updatePlayButton(isPlaying: false)
            playerControls.nowPlayingText("Now Playing: —")
        }
    }

    func updateTimeLabel() {
        let player = AudioPlayerManager.shared
        let current = Int(player.currentTime)
        let duration = Int(player.duration)
        playerControls.updateTimeLabel(current: current, duration: duration)
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
