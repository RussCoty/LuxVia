import UIKit

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Playlist"
        setupUI()

        // ✅ Hook up forward and back buttons
        PlayerControlsView.shared?.onNext = {
            let mgr = AudioPlayerManager.shared
            if mgr.isTrackCued {
                mgr.playCuedTrack()
            } else if mgr.currentSource == .playlist {
                SharedPlaylistManager.shared.playNext()
            } else if mgr.currentSource == .library {
                mgr.playNextInLibrary()
            }
        }

        PlayerControlsView.shared?.onPrevious = {
            let mgr = AudioPlayerManager.shared
            if mgr.isTrackCued {
                mgr.cancelCue()
            } else if mgr.currentSource == .playlist {
                SharedPlaylistManager.shared.playPrevious()
            } else if mgr.currentSource == .library {
                mgr.playPreviousInLibrary()
            }
        }
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
        tableView.allowsSelectionDuringEditing = true

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

        let audio = AudioPlayerManager.shared
        if audio.currentSource == .playlist && audio.currentTrackName == trackName {
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            cell.accessoryType = .checkmark
        } else if audio.isTrackCued && audio.cuedSource == .playlist && audio.cuedTrackName == trackName {
            cell.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
            cell.accessoryType = .detailDisclosureButton
        } else {
            cell.backgroundColor = .clear
            cell.accessoryType = .none
        }

        return cell
    }

    // MARK: - Row Selection (Cue only)

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = SharedPlaylistManager.shared.playlist[indexPath.row]
        AudioPlayerManager.shared.cueTrack(named: selectedTrack, source: .playlist)

        let displayName = selectedTrack.replacingOccurrences(of: "_", with: " ").capitalized
        PlayerControlsView.shared?.nowPlayingText("Cued: \(displayName)")

        tableView.reloadData()
    }

    // MARK: - Scroll to Current Track

    func scrollToNowPlaying() {
        if let currentIndex = SharedPlaylistManager.shared.indexOfCurrentTrack(),
           currentIndex < SharedPlaylistManager.shared.playlist.count {
            let indexPath = IndexPath(row: currentIndex, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
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
            tableView.reloadData()
        }
    }
}
