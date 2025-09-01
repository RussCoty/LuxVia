// File: MusicViewController.swift
// Purpose: Patch to enable delete (red minus) for *imported* audio everywhere it appears.
// Key changes:
// 1) Show delete only for rows backed by a file under Documents/audio (or Documents/audio/imported for legacy).
// 2) Remove hard dependency on folder name == "Imported".
// 3) Ensure table view actually enters/leaves editing mode via setEditing.

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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        print("✅ viewDidLoad: isLoggedIn =", AuthManager.shared.isLoggedIn)
        view.backgroundColor = .white
        title = "Music"

        if navigationItem.rightBarButtonItem == nil { // keep existing button if already set elsewhere
            navigationItem.rightBarButtonItem = editButtonItem
        }

        setupSearch()
        loadGroupedTrackList()
        setupUI()
    }

    /// Propagate edit/done to the table and our flag.
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        isEditingLibrary = editing
        tableView.setEditing(editing, animated: animated)
        tableView.reloadData() // refresh accessories and minus controls
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MiniPlayerManager.shared.setVisible(true)
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

        // Only add tracks that have a corresponding lyric entry in the CSV with a matching audioFileName
        let allLyrics = CSVLyricsLoader.shared.loadLyrics()
        print("[DEBUG] loadGroupedTrackList: loaded \(allLyrics.count) lyrics from CSV")
        let lyricAudioNames = allLyrics.compactMap { $0.audioFileName }
        print("[DEBUG] lyric audioFileNames from CSV: \(lyricAudioNames)")
        func appendTrack(folder: String, fileURL: URL) {
            let title = fileURL.deletingPathExtension().lastPathComponent
            let fileName = fileURL.lastPathComponent // includes extension
            print("[DEBUG] Checking file: \(fileName) against lyric audioFileNames")
            // Find lyric with type == .lyric and audioFileName == fileName
            if let lyric = allLyrics.first(where: { $0.type == .lyric && $0.audioFileName == fileName }) {
                print("[DEBUG] MATCH: \(fileName) == \(lyric.audioFileName ?? "nil") (title: \(lyric.title))")
                let entry = SongEntry(title: title, fileName: fileName, artist: nil, duration: nil)
                tempGroups[folder, default: []].append(entry)
            } else {
                // Try case-insensitive and trimmed match
                let fileNameTrimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if let lyric = allLyrics.first(where: { $0.type == .lyric && ($0.audioFileName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == fileNameTrimmed) }) {
                    print("[DEBUG] CASE/TRIM MATCH: \(fileName) == \(lyric.audioFileName ?? "nil") (title: \(lyric.title))")
                    let entry = SongEntry(title: title, fileName: fileName, artist: nil, duration: nil)
                    tempGroups[folder, default: []].append(entry)
                } else {
                    print("[DEBUG] NO MATCH for file: \(fileName)")
                    // If imported, add anyway as generic track
                    if folder == "Imported" {
                        let entry = SongEntry(title: title, fileName: fileName, artist: nil, duration: nil)
                        tempGroups[folder, default: []].append(entry)
                        print("[DEBUG] Imported file added without lyric: \(fileName)")
                    }
                }
            }
        }

        // Bundle assets
        if let bundleAudioURL = Bundle.main.resourceURL?.appendingPathComponent("Audio"),
           let enumerator = fileManager.enumerator(at: bundleAudioURL, includingPropertiesForKeys: nil) {
            print("[DEBUG] Bundle audio path: \(bundleAudioURL.path)")
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if ext == "mp3" || ext == "wav" {
                    print("[DEBUG] Found audio file in bundle: \(fileURL.lastPathComponent)")
                    let relPath = fileURL.path.replacingOccurrences(of: bundleAudioURL.path + "/", with: "")
                    let folder = relPath.components(separatedBy: "/").dropLast().joined(separator: "/").capitalized
                    appendTrack(folder: folder.isEmpty ? "Music" : folder, fileURL: fileURL)
                }
            }
        }
        // Imported assets live under Documents/audio (optionally /imported/... for legacy)
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let audioRoot = docsURL.appendingPathComponent("audio")
            if fileManager.fileExists(atPath: audioRoot.path),
               let enumerator = fileManager.enumerator(at: audioRoot, includingPropertiesForKeys: nil) {
                print("[DEBUG] Imported audio path: \(audioRoot.path)")
                for case let fileURL as URL in enumerator {
                    let ext = fileURL.pathExtension.lowercased()
                    if ext == "mp3" || ext == "wav" {
                        let debugFolder = "Imported"
                        print("[DEBUG] Found imported audio file: \(fileURL.lastPathComponent) | Assigned folder: \(debugFolder) | Full path: \(fileURL.path)")
                        appendTrack(folder: debugFolder, fileURL: fileURL)
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
        print("[DEBUG] groupedTracks count: \(groupedTracks.count), sortedFolders: \(sortedFolders)")
        tableView.reloadData()
        print("[DEBUG] tableView reloaded with \(SharedLibraryManager.shared.allSongs.count) songs")
    }

    func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.allowsSelectionDuringEditing = true
        tableView.allowsMultipleSelectionDuringEditing = false

        view.addSubview(tableView)
        print("[DEBUG] Added tableView to view hierarchy: tableView.superview = \(String(describing: tableView.superview))")
        print("[DEBUG] tableView frame after add: \(tableView.frame)")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        print("[DEBUG] tableView constraints activated")
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

    // MARK: - Imported file detection
    /// Returns the on-disk URL for an imported track if it exists under Documents/audio or Documents/audio/imported.
    private func importedFileURL(for track: SongEntry) -> URL? {
        let fm = FileManager.default
        guard let docsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let audioRoot = docsURL.appendingPathComponent("audio")
        let direct = audioRoot.appendingPathComponent(track.fileName)
        if fm.fileExists(atPath: direct.path) { return direct }
        let legacy = audioRoot.appendingPathComponent("imported").appendingPathComponent(track.fileName)
        if fm.fileExists(atPath: legacy.path) { return legacy }
        return nil
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
            cell.textLabel?.text = track.title.replacingOccurrences(of: "_", with: " ").capitalized
        }

        // Show + only when NOT editing
        if !tableView.isEditing {
            let addButton = UIButton(type: .contactAdd)
            addButton.tag = indexPath.section * 1000 + indexPath.row
            addButton.addTarget(self, action: #selector(addToServiceTapped(_:)), for: .touchUpInside)
            cell.accessoryView = addButton
        } else {
            cell.accessoryView = nil
        }

        return cell
    }

    // Enable delete control only for imported audio when editing
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard isEditingLibrary else { return false }
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] else { return false }
        return importedFileURL(for: track) != nil
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row]
        let deletable = (isEditingLibrary && track.flatMap { importedFileURL(for: $0) } != nil)
        return deletable ? .delete : .none
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] else { return }

        guard let fileURL = importedFileURL(for: track) else {
            showToast("This track is not deletable.")
            return
        }

        // Prevent deletion if currently playing
        let audioManager = AudioPlayerManager.shared
        if audioManager.isPlaying, let currentTrackName = audioManager.currentTrackName, currentTrackName == track.fileName {
            showToast("Cannot delete: Track is currently playing.")
            return
        }

        // Remove from service list if present
        let serviceManager = ServiceOrderManager.shared
        if let idx = serviceManager.items.firstIndex(where: { $0.fileName == track.fileName }) {
            serviceManager.remove(at: idx)
        }

        // Clear cued position if this track is cued
        if let cuedTrack = audioManager.cuedTrack, cuedTrack.fileName == track.fileName {
            audioManager.cuedTrack = nil
            audioManager.cuedSource = .none
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            showToast("Failed to delete: \(track.title)")
            return
        }

        // Simplest: re-enumerate and reload from disk to stay in sync across sections/filters
        loadGroupedTrackList()
        showToast("Deleted: \(track.title)")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]
        guard let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] else { return }

        AudioPlayerManager.shared.cueTrack(track, source: .library)
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
        // For songs, match lyric strictly by audioFileName and type == .lyric; for others, match by title
        let lyric: Lyric?
        if type == .song {
            lyric = SharedLibraryManager.shared.allReadings.first {
                $0.type == .lyric && $0.audioFileName == entry.fileName
            }
        } else {
            lyric = SharedLibraryManager.shared.allReadings.first {
                $0.title == entry.title
            }
        }
        let serviceItem = ServiceItem(
            type: type,
            title: entry.title,
            subtitle: nil,
            fileName: entry.fileName,
            customText: nil,
            uid: lyric?.uid // Set uid if found, else nil
        )

        print("[DEBUG] Created ServiceItem:")
        print("  id: \(serviceItem.id)")
        print("  type: \(serviceItem.type)")
        print("  title: \(serviceItem.title)")
        print("  subtitle: \(serviceItem.subtitle ?? "nil")")
        print("  fileName: \(serviceItem.fileName ?? "nil")")
        print("  customText: \(serviceItem.customText != nil ? "SET" : "nil")")
        print("  uid: \(serviceItem.uid != nil ? String(serviceItem.uid!) : "nil")")

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
