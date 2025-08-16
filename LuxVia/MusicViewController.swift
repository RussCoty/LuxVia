import UIKit
import UniformTypeIdentifiers

class MusicViewController: BaseViewController,
                           UITableViewDataSource,
                           UITableViewDelegate,
                           UISearchResultsUpdating,
                           UIDocumentPickerDelegate {

    // MARK: - Initializers
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Properties

    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let searchController = UISearchController(searchResultsController: nil)

        var isEditingLibrary: Bool = false

    var groupedTracks: [String: [SongEntry]] = [:]
    var sortedFolders: [String] = []
    var collapsedSections: Set<String> = []

    var filteredGroupedTracks: [String: [SongEntry]] = [:]
    var filteredFolders: [String] = []

    var isFiltering: Bool {
        return !(searchController.searchBar.text?.isEmpty ?? true)
    }

//    var playerView: PlayerControlsView? {
//        return PlayerControlsView.shared
//    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        print("✅ viewDidLoad: isLoggedIn =", AuthManager.shared.isLoggedIn)

//        MiniPlayerManager.shared.attach(to: self)
        view.backgroundColor = .white
        title = "Music"

        setupSearch()
        loadGroupedTrackList()
        setupUI()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MiniPlayerManager.shared.setVisible(true)  // ✅ Re-show MiniPlayer when Music tab appears

    }

    // MARK: - Setup

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
            filteredFolders = temp.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        tableView.reloadData()
    }

    func loadGroupedTrackList() {
        let fileManager = FileManager.default
        var tempGroups: [String: [SongEntry]] = [:]

        func appendTrack(folder: String, fileURL: URL) {
            let title = fileURL.deletingPathExtension().lastPathComponent
            let fileName = fileURL.lastPathComponent // includes extension
            let entry = SongEntry(title: title, fileName: fileName, artist: nil, duration: nil)
            tempGroups[folder, default: []].append(entry)
        }

        if let bundleAudioURL = Bundle.main.resourceURL?.appendingPathComponent("Audio"),
           let enumerator = fileManager.enumerator(at: bundleAudioURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if ext == "mp3" || ext == "wav" {
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
                    let ext = fileURL.pathExtension.lowercased()
                    if ext == "mp3" || ext == "wav" {
                        let relPath = fileURL.path.replacingOccurrences(of: importedURL.path + "/", with: "")
                        let folder = relPath.components(separatedBy: "/").dropLast().joined(separator: "/").capitalized
                        appendTrack(folder: folder.isEmpty ? "Imported" : folder, fileURL: fileURL)
                    }
                }
            }
        }

        for (folder, tracks) in tempGroups {
            tempGroups[folder] = tracks.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }

        groupedTracks = tempGroups
        sortedFolders = tempGroups.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

        SharedLibraryManager.shared.allSongs = tempGroups.values.flatMap { $0 }
        tableView.reloadData()
    }

    func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.allowsSelectionDuringEditing = true
        tableView.allowsMultipleSelectionDuringEditing = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func scrollToTrack(named fileName: String) {
        for (sectionIndex, folder) in sortedFolders.enumerated() {
            if let rowIndex = groupedTracks[folder]?.firstIndex(where: { $0.fileName == fileName }) {
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                return
            }
        }
    }

    // MARK: - TableView

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
        if let track = track {
            // Show only the title
            cell.textLabel?.text = track.title.replacingOccurrences(of: "_", with: " ").capitalized
        }

        // Only show addButton accessory when NOT in editing mode
        if !tableView.isEditing {
            let addButton = UIButton(type: .contactAdd)
            addButton.tag = indexPath.section * 1000 + indexPath.row
            addButton.addTarget(self, action: #selector(addToServiceTapped(_:)), for: .touchUpInside)
            cell.accessoryView = addButton
        } else {
            cell.accessoryView = nil
        }

        // Only show delete indicator for imported audio when editing
        if isEditingLibrary && folder == "Imported" {
            cell.showsReorderControl = false
            cell.selectionStyle = .none
        }
        return cell
    }
    // Enable red minus delete control for imported audio in editing mode
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        // Only allow delete for imported audio
        return isEditingLibrary && folder == "Imported"
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        print("[DEBUG] editingStyleForRowAt: section=\(indexPath.section), folder=\(folder), isEditingLibrary=\(isEditingLibrary)")
        // Only show red minus for imported audio in editing mode
        return (isEditingLibrary && folder == "Imported") ? .delete : .none
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        guard folder == "Imported" else { return }
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] else { return }

        // Remove file from disk
        let fileManager = FileManager.default
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let importedURL = docsURL.appendingPathComponent("audio/imported/").appendingPathComponent(track.fileName)
            do {
                if fileManager.fileExists(atPath: importedURL.path) {
                    try fileManager.removeItem(at: importedURL)
                }
            } catch {
                showToast("Failed to delete: \(track.title)")
                return
            }
        }

        // Remove from data source and reload
        groupedTracks[folder]?.remove(at: indexPath.row)
        loadGroupedTrackList()
        showToast("Deleted: \(track.title)")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] else { return }

    AudioPlayerManager.shared.cueTrack(track, source: .library)

    // Show only the title in now playing area
    PlayerControlsView.shared?.updateCuedTrackText(track.title.replacingOccurrences(of: "_", with: " ").capitalized)

    MiniPlayerManager.shared.show()

    tableView.reloadData()
    }

    @objc func addToServiceTapped(_ sender: UIButton) {
        let section = sender.tag / 1000
        let row = sender.tag % 1000
        let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[row] else { return }

        let trimmedTitle = track.title.replacingOccurrences(of: ".mp3", with: "")
        guard let entry = SharedLibraryManager.shared.songForTrack(named: trimmedTitle) else {
            showToast("MP3 not found for: \(track.title)")
            return
        }

        let alert = UIAlertController(title: "Add to Service", message: "Add as song or background music?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Song", style: .default) { _ in
            self.addMusicEntry(entry, type: .song)
        })
        alert.addAction(UIAlertAction(title: "Background Music", style: .default) { _ in
            self.addMusicEntry(entry, type: .background)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }

    private func addMusicEntry(_ entry: SongEntry, type: ServiceItemType) {
        let serviceItem = ServiceItem(
            type: type,
            title: entry.title,
            subtitle: nil,
            fileName: entry.fileName,
            customText: nil
        )

        if ServiceOrderManager.shared.items.contains(where: { $0.fileName == entry.fileName && $0.type == type }) {
            showToast("Already in Order: \(entry.title)")
            return
        }

        ServiceOrderManager.shared.add(serviceItem)
        showToast("Added: \(entry.title)")
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
