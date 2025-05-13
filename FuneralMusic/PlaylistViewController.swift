import UIKit

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    var currentTrackIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Playlist"
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        scrollToNowPlaying()
    }

    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.setEditing(true, animated: false)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - TableView Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedPlaylistManager.shared.playlist.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "PlaylistCell")
        let trackName = SharedPlaylistManager.shared.playlist[indexPath.row]
        cell.textLabel?.text = trackName.capitalized

        if indexPath.row == currentTrackIndex && AudioPlayerManager.shared.isPlaying {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        }

        return cell
    }

    // MARK: - Row Selection (no autoplay)

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentTrackIndex = indexPath.row
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Playback

    func playTrack(at index: Int) {
        let playlist = SharedPlaylistManager.shared.playlist
        guard index < playlist.count else { return }

        let track = playlist[index]
        guard let url = Bundle.main.url(forResource: track, withExtension: "mp3", subdirectory: "Audio") else { return }

        currentTrackIndex = index
        AudioPlayerManager.shared.play(url: url)

        PlayerControlsView.shared?.nowPlayingText("Now Playing: \(track.replacingOccurrences(of: "_", with: " ").capitalized)")

        tableView.reloadData()
        scrollToNowPlaying()
    }

    func playPlaylistFromStart() {
        guard !SharedPlaylistManager.shared.playlist.isEmpty else { return }
        currentTrackIndex = 0
        playTrack(at: currentTrackIndex)
    }

    func scrollToNowPlaying() {
        guard currentTrackIndex < SharedPlaylistManager.shared.playlist.count else { return }
        let indexPath = IndexPath(row: currentTrackIndex, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }

    // MARK: - Reordering

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var playlist = SharedPlaylistManager.shared.playlist
        let movedItem = playlist.remove(at: sourceIndexPath.row)
        playlist.insert(movedItem, at: destinationIndexPath.row)
        SharedPlaylistManager.shared.playlist = playlist
    }

    // MARK: - Swipe to Delete

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SharedPlaylistManager.shared.playlist.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)

            if currentTrackIndex >= SharedPlaylistManager.shared.playlist.count {
                currentTrackIndex = max(0, SharedPlaylistManager.shared.playlist.count - 1)
            }
            tableView.reloadData()
        }
    }
}
