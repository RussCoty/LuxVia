import UIKit

class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView(frame: .zero, style: .insetGrouped)

    var groupedTracks: [String: [String]] = [:]
    var sortedFolders: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music Library"

        loadGroupedTrackList()
        setupUI()
    }

    func loadGroupedTrackList() {
        guard let baseURL = Bundle.main.resourceURL?.appendingPathComponent("Audio") else {
            print("❌ Audio folder not found")
            return
        }

        var tempGroups: [String: [String]] = [:]

        if let enumerator = FileManager.default.enumerator(at: baseURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension.lowercased() == "mp3" {
                    let relativePath = fileURL.path.replacingOccurrences(of: baseURL.path + "/", with: "")
                    let components = relativePath.components(separatedBy: "/")
                    let folder = components.dropLast().joined(separator: "/").isEmpty ? "Root" : components.dropLast().joined(separator: "/")
                    let name = fileURL.deletingPathExtension().lastPathComponent

                    tempGroups[folder, default: []].append(name)
                }
            }
        }

        // Sort filenames and section names
        for (folder, tracks) in tempGroups {
            tempGroups[folder] = tracks.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })
        }

        self.groupedTracks = tempGroups
        self.sortedFolders = tempGroups.keys.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })

        tableView.reloadData()
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedFolders.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let folder = sortedFolders[section]
        return groupedTracks[folder]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedFolders[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let folder = sortedFolders[indexPath.section]
        let track = groupedTracks[folder]?[indexPath.row] ?? ""
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "TrackCell")
        cell.textLabel?.text = track.replacingOccurrences(of: "_", with: " ").capitalized

        let addButton = UIButton(type: .contactAdd)
        addButton.tag = indexPath.section * 1000 + indexPath.row
        addButton.addTarget(self, action: #selector(addToPlaylistTapped(_:)), for: .touchUpInside)
        cell.accessoryView = addButton

        let audio = AudioPlayerManager.shared
        if audio.currentSource == .library && audio.currentTrackName == track {
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            cell.accessoryType = .checkmark
        } else if audio.isTrackCued && audio.cuedSource == .library && audio.cuedTrackName == track {
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
        let folder = sortedFolders[indexPath.section]
        let track = groupedTracks[folder]?[indexPath.row] ?? ""
        AudioPlayerManager.shared.cueTrack(named: track, source: .library)

        PlayerControlsView.shared?.nowPlayingText("Cued: \(track.replacingOccurrences(of: "_", with: " ").capitalized)")
        tableView.reloadData()
    }

    // MARK: Add to Playlist

    @objc func addToPlaylistTapped(_ sender: UIButton) {
        let section = sender.tag / 1000
        let row = sender.tag % 1000
        let folder = sortedFolders[section]
        guard let track = groupedTracks[folder]?[row] else { return }

        if SharedPlaylistManager.shared.playlist.contains(track) {
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

        UIView.animate(withDuration: 0.35) {
            banner.alpha = 1.0
            banner.frame.origin.y -= (bannerHeight + 100)
        }

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
