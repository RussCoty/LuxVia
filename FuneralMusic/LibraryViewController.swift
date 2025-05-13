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

        // Add button to add to playlist
        let addButton = UIButton(type: .contactAdd)
        addButton.tag = indexPath.row
        addButton.addTarget(self, action: #selector(addToPlaylistTapped(_:)), for: .touchUpInside)
        cell.accessoryView = addButton

        // Highlight current playing track
        let currentlyPlaying = AudioPlayerManager.shared.currentTrackName
        if trackName == currentlyPlaying {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
        // Highlight selected (tapped) row
        else if indexPath.row == selectedTrackIndex {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .darkGray
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
        // Normal
        else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        }

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTrackIndex = indexPath.row
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
