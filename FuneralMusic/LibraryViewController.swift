import UIKit
import UniformTypeIdentifiers

class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIDocumentPickerDelegate {

    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let searchController = UISearchController(searchResultsController: nil)

    var groupedTracks: [String: [SongEntry]] = [:]
    var sortedFolders: [String] = []
    var collapsedSections: Set<String> = []

    var filteredGroupedTracks: [String: [SongEntry]] = [:]
    var filteredFolders: [String] = []

    var isFiltering: Bool {
        return !(searchController.searchBar.text?.isEmpty ?? true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music Library"

        setupSearch()
        loadGroupedTrackList()
        setupUI()
        setupUserMenu()

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

    func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Tracks"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        if query.isEmpty {
            filteredGroupedTracks = [:]
            filteredFolders = []
        } else {
            var temp: [String: [SongEntry]] = [:]
            for (folder, tracks) in groupedTracks {
                let matches = tracks.filter { $0.title.lowercased().contains(query) }
                if !matches.isEmpty {
                    temp[folder] = matches
                }
            }
            filteredGroupedTracks = temp
            filteredFolders = temp.keys.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })
        }
        tableView.reloadData()
    }

    func loadGroupedTrackList() {
        let fileManager = FileManager.default
        var tempGroups: [String: [SongEntry]] = [:]

        func appendTrack(folder: String, fileURL: URL) {
            let title = fileURL.deletingPathExtension().lastPathComponent
            let entry = SongEntry(title: title, fileName: title, artist: nil, duration: nil)
            tempGroups[folder, default: []].append(entry)
        }

        if let bundleAudioURL = Bundle.main.resourceURL?.appendingPathComponent("Audio"),
           let enumerator = fileManager.enumerator(at: bundleAudioURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension.lowercased() == "mp3" {
                    let relPath = fileURL.path.replacingOccurrences(of: bundleAudioURL.path + "/", with: "")
                    let folder = relPath.components(separatedBy: "/").dropLast().joined(separator: "/").capitalized
                    appendTrack(folder: folder.isEmpty ? "Music" : folder, fileURL: fileURL)
                }
            }
        }

        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let importedURL = docsURL.appendingPathComponent("audio")
            if fileManager.fileExists(atPath: importedURL.path),
               let enumerator = fileManager.enumerator(at: importedURL, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "mp3" {
                        let relPath = fileURL.path.replacingOccurrences(of: importedURL.path + "/", with: "")
                        let folder = relPath.components(separatedBy: "/").dropLast().joined(separator: "/").capitalized
                        appendTrack(folder: folder.isEmpty ? "Imported" : folder, fileURL: fileURL)
                    }
                }
            }
        }

        for (folder, tracks) in tempGroups {
            tempGroups[folder] = tracks.sorted(by: { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
        }

        groupedTracks = tempGroups
        sortedFolders = tempGroups.keys.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })

        SharedLibraryManager.shared.allSongs = tempGroups.values.flatMap { $0 }
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return isFiltering ? filteredFolders.count : sortedFolders.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]
        return (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row]

        let cell = UITableViewCell(style: .value1, reuseIdentifier: "TrackCell")
        cell.textLabel?.text = track?.title.replacingOccurrences(of: "_", with: " ").capitalized

        let addButton = UIButton(type: .contactAdd)
        addButton.tag = indexPath.section * 1000 + indexPath.row
        addButton.addTarget(self, action: #selector(addToPlaylistTapped(_:)), for: .touchUpInside)
        cell.accessoryView = addButton
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] else { return }

        AudioPlayerManager.shared.cueTrack(track, source: .library)
        PlayerControlsView.shared?.nowPlayingText("Cued: \(track.title.replacingOccurrences(of: "_", with: " ").capitalized)")
        tableView.reloadData()
    }

    @objc func addToPlaylistTapped(_ sender: UIButton) {
        let section = sender.tag / 1000
        let row = sender.tag % 1000
        let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[row] else { return }

        if SharedPlaylistManager.shared.playlist.contains(where: { $0.title == track.title }) {
            let alert = UIAlertController(
                title: "Add Again?",
                message: "\"\(track.title.capitalized)\" is already in the playlist. Add it again?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Add Again", style: .default) { _ in
                SharedPlaylistManager.shared.playlist.append(track)
                SharedPlaylistManager.shared.save()
                self.showToast("Added again: \(track.title)")
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            SharedPlaylistManager.shared.playlist.append(track)
            SharedPlaylistManager.shared.save()
            showToast("Added: \(track.title)")
        }
    }

    private func setupUserMenu() {
        let menuButton = UIBarButtonItem(title: "⋯", style: .plain, target: self, action: #selector(showUserMenu))
        navigationItem.rightBarButtonItem = menuButton
    }

    @objc private func showUserMenu() {
        let status = AuthManager.shared.isLoggedIn ? "Member: Active" : "Guest"
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: status, style: .default))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in AuthManager.shared.logout() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.backgroundColor = UIColor.systemGreen
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 6
        toastLabel.clipsToBounds = true
        toastLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let padding: CGFloat = 12
        toastLabel.frame = CGRect(
            x: padding,
            y: view.safeAreaInsets.top + 16,
            width: view.frame.width - padding * 2,
            height: 36
        )
        view.addSubview(toastLabel)

        UIView.animate(withDuration: 0.25, animations: {
            toastLabel.alpha = 1.0
            toastLabel.transform = .identity
        }) { _ in
            UIView.animate(
                withDuration: 0.25,
                delay: 2.0,
                options: .curveEaseInOut,
                animations: {
                    toastLabel.alpha = 0.0
                    toastLabel.transform = CGAffineTransform(translationX: 0, y: -10)
                }, completion: { _ in
                    toastLabel.removeFromSuperview()
                }
            )
        }
    }
}
