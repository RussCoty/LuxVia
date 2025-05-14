import UIKit

class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    var tracks: [String] = []
    var selectedTrackIndex: Int? = nil

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
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "TrackCell")
        let trackName = tracks[indexPath.row]
        cell.textLabel?.text = trackName.capitalized

        let addButton = UIButton(type: .contactAdd)
        addButton.tag = indexPath.row
        addButton.addTarget(self, action: #selector(addToPlaylistTapped(_:)), for: .touchUpInside)
        cell.accessoryView = addButton

        // 🔷 Highlight if cued or playing
        let audio = AudioPlayerManager.shared
        if audio.currentSource == .library && audio.currentTrackName == trackName {
            cell.textLabel?.textColor = .systemBlue
            cell.accessoryType = .checkmark
        } else if audio.isTrackCued && audio.cuedSource == .library && audio.cuedTrackName == trackName {
            cell.textLabel?.textColor = .systemGray
            cell.accessoryType = .detailDisclosureButton
        } else {
            cell.textLabel?.textColor = .label
            cell.accessoryType = .none
        }

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = tracks[indexPath.row]
        AudioPlayerManager.shared.cueTrack(named: selectedTrack, source: .library)

        let displayName = selectedTrack.replacingOccurrences(of: "_", with: " ").capitalized
        PlayerControlsView.shared?.nowPlayingText("Cued: \(displayName)")

        tableView.reloadData()
    }



    @objc func addToPlaylistTapped(_ sender: UIButton) {
        let track = tracks[sender.tag]
        if !SharedPlaylistManager.shared.playlist.contains(track) {
            SharedPlaylistManager.shared.playlist.append(track)
            print("✅ Added to playlist: \(track)")
        }
    }
}
