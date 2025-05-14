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
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            cell.accessoryType = .checkmark
        } else if audio.isTrackCued && audio.cuedSource == .library && audio.cuedTrackName == trackName {
            cell.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
            cell.accessoryType = .detailDisclosureButton
        } else {
            cell.backgroundColor = .clear
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

        if SharedPlaylistManager.shared.playlist.contains(track) {
            // Confirm duplicate addition
            let alert = UIAlertController(
                title: "Add Again?",
                message: "\"\(track.replacingOccurrences(of: "_", with: " ").capitalized)\" is already in the playlist. Add it again?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Add Again", style: .default) { _ in
                SharedPlaylistManager.shared.playlist.append(track)
                self.showConfirmationBanner(for: track)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
        } else {
            SharedPlaylistManager.shared.playlist.append(track)
            showConfirmationBanner(for: track)
        }
    }
    func showConfirmationBanner(for track: String) {
        let banner = UILabel()
        banner.text = "“\(track.replacingOccurrences(of: "_", with: " ").capitalized)” added to playlist ✅"
        banner.textColor = .white
        banner.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.95)
        banner.font = UIFont.boldSystemFont(ofSize: 14)
        banner.textAlignment = .center
        banner.numberOfLines = 2
        banner.layer.cornerRadius = 10
        banner.layer.masksToBounds = true

        let bannerHeight: CGFloat = 50
        banner.frame = CGRect(x: 40, y: view.frame.height, width: view.frame.width - 80, height: bannerHeight)
        banner.alpha = 0

        view.addSubview(banner)

        // Animate in
        UIView.animate(withDuration: 0.35, animations: {
            banner.alpha = 1.0
            banner.frame.origin.y -= (bannerHeight + 100)
        })

        // Animate out after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            UIView.animate(withDuration: 0.35, animations: {
                banner.alpha = 0.0
                banner.frame.origin.y += 40
            }, completion: { _ in
                banner.removeFromSuperview()
            })
        }
    }

}
