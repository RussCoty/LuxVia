import UIKit
import UniformTypeIdentifiers

class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIDocumentPickerDelegate {

    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let searchController = UISearchController(searchResultsController: nil)
    private var importButton: UIButton!

    var groupedTracks: [String: [String]] = [:]
    var sortedFolders: [String] = []
    var collapsedSections: Set<String> = []

    var filteredGroupedTracks: [String: [String]] = [:]
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
        setupImportButton()
        setupUserMenu()
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
            var temp: [String: [String]] = [:]
            for (folder, tracks) in groupedTracks {
                let matches = tracks.filter { $0.lowercased().contains(query) }
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
        var tempGroups: [String: [String]] = [:]

        // Built-in audio from app bundle
        if let bundleAudioURL = Bundle.main.resourceURL?.appendingPathComponent("Audio") {
            if let enumerator = fileManager.enumerator(at: bundleAudioURL, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "mp3" {
                        let relativePath = fileURL.path.replacingOccurrences(of: bundleAudioURL.path + "/", with: "")
                        let components = relativePath.components(separatedBy: "/")
                        let folder = components.dropLast().joined(separator: "/").isEmpty ? " Music" : components.dropLast().joined(separator: "/")
                        let name = fileURL.deletingPathExtension().lastPathComponent
                        tempGroups[folder, default: []].append(name)
                    }
                }
            }
        }

        // Imported audio from documents
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let importedURL = docsURL.appendingPathComponent("audio")
            if fileManager.fileExists(atPath: importedURL.path) {
                if let enumerator = fileManager.enumerator(at: importedURL, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        if fileURL.pathExtension.lowercased() == "mp3" {
                            let relativePath = fileURL.path.replacingOccurrences(of: importedURL.path + "/", with: "")
                            let components = relativePath.components(separatedBy: "/")
                            let folder = components.dropLast().joined(separator: "/").isEmpty ? "Imported" : components.dropLast().joined(separator: "/")
                            let name = fileURL.deletingPathExtension().lastPathComponent
                            tempGroups[folder, default: []].append(name)
                        }
                    }
                }
            }
        }

        for (folder, tracks) in tempGroups {
            tempGroups[folder] = tracks.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })
        }

        groupedTracks = tempGroups
        sortedFolders = tempGroups.keys.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })
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

    private func setupImportButton() {
        importButton = UIButton(type: .system)
        importButton.setTitle("Import", for: .normal)
        importButton.backgroundColor = .systemBlue
        importButton.setTitleColor(.white, for: .normal)
        importButton.layer.cornerRadius = 20
        importButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        importButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        importButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(importButton)

        NSLayoutConstraint.activate([
            importButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            importButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -76)
        ])

        importButton.addTarget(self, action: #selector(importTapped), for: .touchUpInside)
    }

    @objc private func importTapped() {
        let mp3Type = UTType(filenameExtension: "mp3")!
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [mp3Type], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else { return }

        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let importedFolderURL = docsURL.appendingPathComponent("audio/imported")

        do {
            if !fileManager.fileExists(atPath: importedFolderURL.path) {
                try fileManager.createDirectory(at: importedFolderURL, withIntermediateDirectories: true)
            }

            let destinationURL = importedFolderURL.appendingPathComponent(pickedURL.lastPathComponent)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.copyItem(at: pickedURL, to: destinationURL)
            loadGroupedTrackList()
        } catch {
            print("❌ Failed to import: \(error)")
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return isFiltering ? filteredFolders.count : sortedFolders.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]
        if collapsedSections.contains(folder) && !isFiltering {
            return 0
        }
        return (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]
        let isCollapsed = collapsedSections.contains(folder)
        let icon = isCollapsed && !isFiltering ? "▶︎" : "▼"

        let label = UILabel()
        label.text = "\(icon) \(folder)"
        label.font = .boldSystemFont(ofSize: 16)

        let tapView = UIView()
        tapView.backgroundColor = .clear
        tapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSection(_:))))
        tapView.tag = section

        let container = UIView()
        container.addSubview(label)
        container.addSubview(tapView)
        label.translatesAutoresizingMaskIntoConstraints = false
        tapView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),

            tapView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tapView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tapView.topAnchor.constraint(equalTo: container.topAnchor),
            tapView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    @objc func toggleSection(_ sender: UITapGestureRecognizer) {
        guard let section = sender.view?.tag, !isFiltering else { return }
        let folder = sortedFolders[section]

        if collapsedSections.contains(folder) {
            collapsedSections.remove(folder)
        } else {
            collapsedSections.insert(folder)
        }
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] ?? ""

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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] ?? ""
        AudioPlayerManager.shared.cueTrack(named: track, source: .library)

        PlayerControlsView.shared?.nowPlayingText("Cued: \(track.replacingOccurrences(of: "_", with: " ").capitalized)")
        tableView.reloadData()
    }

    @objc func addToPlaylistTapped(_ sender: UIButton) {
        let section = sender.tag / 1000
        let row = sender.tag % 1000
        let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[row] else { return }

        if SharedPlaylistManager.shared.playlist.contains(track) {
            let alert = UIAlertController(
                title: "Add Again?",
                message: "\"\(track.replacingOccurrences(of: "_", with: " ").capitalized)\" is already in the playlist. Add it again?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Add Again", style: .default) { _ in
                SharedPlaylistManager.shared.playlist.append(track)
                self.showToast(message: "✅ Added: \(track.replacingOccurrences(of: "_", with: " ").capitalized)")
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
        } else {
            SharedPlaylistManager.shared.playlist.append(track)
            self.showToast(message: "✅ Added: \(track.replacingOccurrences(of: "_", with: " ").capitalized)")
        }
    }

    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toast = PaddedLabel()
        toast.text = message
        toast.textAlignment = .center
        toast.backgroundColor = UIColor(red: 0.27, green: 0.84, blue: 0.47, alpha: 1.0)
        toast.textColor = .white
        toast.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        toast.alpha = 0
        toast.layer.cornerRadius = 18
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])

        toast.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.25, animations: {
            toast.alpha = 1.0
            toast.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: duration, options: .curveEaseInOut, animations: {
                toast.alpha = 0.0
                toast.transform = CGAffineTransform(translationX: 0, y: -10)
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        }
    }

    private func setupUserMenu() {
        let menuButton = UIBarButtonItem(title: "⋯", style: .plain, target: self, action: #selector(showUserMenu))
        navigationItem.rightBarButtonItem = menuButton
    }

    @objc private func showUserMenu() {
        let status = AuthManager.shared.isLoggedIn ? "Member: Active" : "Guest"

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: status, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            AuthManager.shared.logout()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }
}
