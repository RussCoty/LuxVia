// File: LuxVia/ServiceViewController.swift
import UIKit
import Foundation
import WebKit

// Import tutorial system components
// Note: ContextualTourManager and TutorialManager are defined in separate files

fileprivate func logMiniPlayer(_ context: String, visible: Bool) {
    print("🎛️ MiniPlayer visibility set to \(visible ? "VISIBLE" : "HIDDEN") — from \(context)")
}

extension String {
    var normalized: String {
        return self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Notification.Name {
    static let AudioPlayerTrackChanged = Notification.Name("AudioPlayerTrackChanged")
}

class ServiceViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let segmentedControl = UISegmentedControl(items: ["Service", "Details", "Booklet"])
    private let tableView = UITableView()
    private let containerView = UIView()

    private let bookletFormVC = BookletInfoFormViewController()
    private let bookletGeneratorVC = PDFBookletPreviewViewController()

    private var lastTappedIndexPath: IndexPath?
    private var highlightedFlashIndex: IndexPath?
    private var playbackTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        definesPresentationContext = true
        providesPresentationContextTransitionStyle = true

        // Observe service updates so new/removed/reordered items appear instantly.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleServiceItemsUpdated),
            name: .serviceItemsUpdated,
            object: nil
        )

        setupNavigationBar()
        setupContainerView()
        setupTableView()
        setupBookletFormView()
        setupBookletGeneratorView()

        segmentedControl.selectedSegmentIndex = 0
        segmentChanged(segmentedControl)
        updateMiniPlayerVisibility()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackChange),
            name: .AudioPlayerTrackChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMiniPlayerHeight(_:)),
            name: NSNotification.Name("MiniPlayerHeightChanged"),
            object: nil
        )

        startPlaybackProgressTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateMiniPlayerVisibility()
        logMiniPlayer("viewDidAppear", visible: segmentedControl.selectedSegmentIndex == 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure latest data when returning to the tab.
        tableView.reloadData()
        updateMiniPlayerVisibility()
        logMiniPlayer("viewWillAppear", visible: segmentedControl.selectedSegmentIndex == 0)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNavigationBar() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
        
        // Add help button
        let helpButton = UIBarButtonItem(
            image: UIImage(systemName: "questionmark.circle"),
            style: .plain,
            target: self,
            action: #selector(helpTapped)
        )
        navigationItem.rightBarButtonItem = helpButton
    }

    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        tableView.backgroundColor = .clear
        tableView.separatorInset = .zero

        tableView.allowsSelection = true
        tableView.allowsSelectionDuringEditing = true
        tableView.allowsMultipleSelection = false
        tableView.allowsMultipleSelectionDuringEditing = false

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 250, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 250, right: 0)

        containerView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func setupBookletFormView() {
        addChild(bookletFormVC)
        containerView.addSubview(bookletFormVC.view)
        bookletFormVC.didMove(toParent: self)
        bookletFormVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bookletFormVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            bookletFormVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bookletFormVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bookletFormVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        bookletFormVC.view.isHidden = true
    }

    private func setupBookletGeneratorView() {
        addChild(bookletGeneratorVC)
        containerView.addSubview(bookletGeneratorVC.view)
        bookletGeneratorVC.didMove(toParent: self)
        bookletGeneratorVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bookletGeneratorVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            bookletGeneratorVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bookletGeneratorVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bookletGeneratorVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        bookletGeneratorVC.view.isHidden = true
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        updateMiniPlayerVisibility()
        let index = sender.selectedSegmentIndex
        tableView.setEditing(false, animated: true)
        navigationItem.leftBarButtonItem = (index == 0) ? UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        ) : nil
        tableView.isHidden = index != 0
        bookletFormVC.view.isHidden = index != 1
        bookletGeneratorVC.view.isHidden = index != 2

        if index == 2 {
            bookletGeneratorVC.regeneratePDF()
        }
    }

    @objc private func editButtonTapped() {
        let newEditing = !tableView.isEditing
        tableView.setEditing(newEditing, animated: true)
        navigationItem.leftBarButtonItem?.title = newEditing ? "Done" : "Edit"
        if newEditing {
            // Stop periodic reloads; they fight with reordering gestures.
            playbackTimer?.invalidate()
        } else {
            startPlaybackProgressTimer()
        }
    }
    
    @objc private func helpTapped() {
        let alert = UIAlertController(title: "Help & Tours", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "App Tour", style: .default) { _ in
            TutorialManager.shared.presentAppTour(from: self)
        })
        
        alert.addAction(UIAlertAction(title: "Interactive Service Tour", style: .default) { _ in
            self.showServiceInteractiveTour()
        })
        
        alert.addAction(UIAlertAction(title: "Service Planning Help", style: .default) { _ in
            self.showServiceHelp()
        })
        
        alert.addAction(UIAlertAction(title: "Booklet Guide", style: .default) { _ in
            self.showBookletGuide()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func showServiceInteractiveTour() {
        let tourAlert = UIAlertController(
            title: "📋 Service Planning Interactive Guide",
            message: """Master service planning with these features:

📝 Sections: Use the tabs to switch between Service, Details, and Booklet
✏️ Edit Mode: Reorder items by dragging in edit mode
🎵 Service Order: Add music and readings to build your service
📷 Details: Enter service information and photos
📄 Booklet: Generate professional PDF booklets

Tip: Plan your service order carefully for a smooth ceremony!""",
            preferredStyle: .alert
        )
        
        tourAlert.addAction(UIAlertAction(title: "Try Booklet Guide", style: .default) { _ in
            self.showBookletGuide()
        })
        tourAlert.addAction(UIAlertAction(title: "Perfect!", style: .cancel))
        present(tourAlert, animated: true)
    }
    
    private func showServiceHelp() {
        let helpVC = UIAlertController(
            title: "Service Planning Help",
            message: """
            • Use the Service tab to organize your funeral order
            • Add music and readings to create your service flow
            • Edit mode allows you to reorder items by dragging
            • The Details tab lets you enter service information
            • Generate professional booklets in the Booklet tab
            
            Tip: Plan your service order carefully for a smooth ceremony.
            """,
            preferredStyle: .alert
        )
        
        helpVC.addAction(UIAlertAction(title: "Got it", style: .default))
        present(helpVC, animated: true)
    }
    
    private func showBookletGuide() {
        let bookletVC = UIAlertController(
            title: "Booklet Creation Guide",
            message: """
            1. Fill in service details in the Details tab
            2. Add a photo of the deceased (optional)
            3. Include service information: location, date, time
            4. Add celebrant and other service details
            5. Generate PDF booklet for printing
            
            Your booklet will include all service items and readings for attendees.
            """,
            preferredStyle: .alert
        )
        
        bookletVC.addAction(UIAlertAction(title: "Show App Tour", style: .default) { _ in
            TutorialManager.shared.presentAppTour(from: self)
        })
        bookletVC.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(bookletVC, animated: true)
    }

    @objc private func handleTrackChange() {
        if let current = AudioPlayerManager.shared.currentTrack {
            MiniPlayerManager.shared.updateNowPlayingTrack(current.title)
        } else {
            MiniPlayerManager.shared.clearTrackText()
        }
        tableView.reloadData()
    }

    @objc private func handleMiniPlayerHeight(_ notification: Notification) {
        guard let height = notification.userInfo?["height"] as? CGFloat else { return }
        tableView.contentInset.bottom = height
        tableView.verticalScrollIndicatorInsets.bottom = height
    }

    private func updateMiniPlayerVisibility() {
        let shouldShow = segmentedControl.selectedSegmentIndex == 0 && navigationController?.topViewController == self
        logMiniPlayer("updateMiniPlayerVisibility()", visible: shouldShow)
        MiniPlayerManager.shared.setVisible(shouldShow)
    }

    private func item(for indexPath: IndexPath) -> ServiceItem? {
        guard indexPath.row < ServiceOrderManager.shared.items.count else { return nil }
        return ServiceOrderManager.shared.items[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ServiceOrderManager.shared.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = item(for: indexPath) else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let isPlaying = item.fileName != nil && item.fileName == AudioPlayerManager.shared.currentTrack?.fileName

        let typeText: String = (isPlaying && item.type == .song) ? "Show Lyrics" : item.type.rawValue.capitalized

        cell.textLabel?.text = "• \(item.title) (\(typeText))"
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .none
        cell.selectionStyle = .none

        // Keep layout stable in edit mode; drag handle only.
        cell.showsReorderControl = tableView.isEditing

        isPlaying ? addProgressBar(to: cell, for: item) : removeProgressBar(from: cell)

        if indexPath == highlightedFlashIndex {
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.35)
        } else if indexPath == lastTappedIndexPath {
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.25)
        } else {
            cell.backgroundColor = .clear
        }

        return cell
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastTappedIndexPath = indexPath
        guard let item = item(for: indexPath) else { return }

        if item.type == .reading || item.type == .customReading {
            // If customReading has audio, play it; otherwise show text preview
            if let fileName = item.fileName, !fileName.isEmpty {
                // Try to find the custom recording in the shared library
                if let customRecording = SharedLibraryManager.shared.allSongs.first(where: { $0.fileName == fileName }) {
                    AudioPlayerManager.shared.cueTrack(customRecording, source: .library)
                    MiniPlayerManager.shared.updateCuedTrackText(customRecording.title)
                    highlightedFlashIndex = indexPath
                    tableView.reloadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if self.highlightedFlashIndex == indexPath {
                            self.highlightedFlashIndex = nil
                            tableView.reloadRows(at: [indexPath], with: .fade)
                        }
                    }
                    return
                } else {
                    // Fallback: create a custom SongEntry for the recording and cue it
                    let customTrack = SongEntry(
                        title: item.title,
                        fileName: fileName,
                        artist: nil,
                        duration: nil
                    )
                    AudioPlayerManager.shared.cueTrack(customTrack, source: .library)
                    MiniPlayerManager.shared.updateCuedTrackText(item.title)
                    highlightedFlashIndex = indexPath
                    tableView.reloadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if self.highlightedFlashIndex == indexPath {
                            self.highlightedFlashIndex = nil
                            tableView.reloadRows(at: [indexPath], with: .fade)
                        }
                    }
                    return
                }
            }
            // Fallback: show text preview
            if let text = item.customText {
                logMiniPlayer("didSelectRowAt (reading)", visible: false)
                if !UIApplication.isServiceTabActive() {
                    MiniPlayerManager.shared.setVisible(false)
                }
                let preview = ReadingPreviewViewController(title: item.title, text: text)
                navigationController?.pushViewController(preview, animated: true)
                tableView.reloadData()
                return
            }
        }

        if [.song, .background, .music].contains(item.type),
           let fileName = item.fileName {
            let isCued = AudioPlayerManager.shared.currentTrack?.fileName == fileName

            if isCued, let lyrics = lyricForPlayingTrack() {
                print("🎤 Showing lyrics for cued track: \(lyrics.title)")
                if !UIApplication.isServiceTabActive() {
                    MiniPlayerManager.shared.setVisible(false)
                }
                let preview = ReadingPreviewViewController(title: "Lyrics", text: lyrics.body)
                navigationController?.pushViewController(preview, animated: true)
                return
            }

            if let song = SharedLibraryManager.shared.allSongs.first(where: { $0.fileName == fileName }) {
                AudioPlayerManager.shared.cueTrack(song, source: .library)
                MiniPlayerManager.shared.updateCuedTrackText(song.title)

                highlightedFlashIndex = indexPath
                tableView.reloadData()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if self.highlightedFlashIndex == indexPath {
                        self.highlightedFlashIndex = nil
                        self.tableView.reloadRows(at: [indexPath], with: .fade)
                    }
                }
            }
        }
    }

    // MARK: - Editing / Deleting

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // Only show red '-' while in edit mode.
        return tableView.isEditing ? .delete : .none
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        // Confirm before destructive action (to prevent accidental deletes while reordering).
        let alert = UIAlertController(title: "Delete Item?",
                                      message: "This will remove the service item from the order.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // Check if the deleted item is currently cued
            if let deletedItem = ServiceOrderManager.shared.items[safe: indexPath.row],
               let cuedTrack = AudioPlayerManager.shared.cuedTrack,
               deletedItem.fileName != nil,
               deletedItem.fileName == cuedTrack.fileName {
                AudioPlayerManager.shared.cancelCue()
                // Do not clear now playing text; keep it as is
            }
            ServiceOrderManager.shared.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        })
        present(alert, animated: true)
    }

    // Remove swipe-to-delete entirely by not implementing trailingSwipeActionsConfigurationForRowAt.

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView,
                   moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {
        guard let fromItem = item(for: sourceIndexPath),
              let toItem = item(for: destinationIndexPath),
              let fromIndex = ServiceOrderManager.shared.items.firstIndex(where: { $0.id == fromItem.id }),
              let toIndex = ServiceOrderManager.shared.items.firstIndex(where: { $0.id == toItem.id }) else { return }

        ServiceOrderManager.shared.move(from: fromIndex, to: toIndex)
        ServiceOrderManager.shared.save()
        // No reload here; UIKit animates move smoothly. Extra reloads cause jitter.
    }

    func lyricForPlayingTrack() -> Lyric? {
        guard let currentTrack = AudioPlayerManager.shared.currentTrack else {
            print("❌ No current track available.")
            return nil
        }

        let allLyrics = SharedLibraryManager.shared.allReadings

        print("🎧 Current track:")
        print("   • title = '\(currentTrack.title)'")
        print("   • fileName = '\(currentTrack.fileName)'")

        print("📄 Available lyrics with audio file names:")
        for lyric in allLyrics {
            if let audioName = lyric.audioFileName {
                print("   • '\(audioName)' → title = '\(lyric.title)'")
            }
        }

        let normalizedCurrentFileName = currentTrack.fileName.normalizedFilename
        print("🔍 Normalized current track fileName: '\(normalizedCurrentFileName)'")

        if let byFileName = allLyrics.first(where: {
            guard let audioName = $0.audioFileName else { return false }
            let normalizedAudioName = audioName.normalizedFilename
            print("   ↳ Comparing normalized audioFileName: '\(normalizedAudioName)'")
            return normalizedAudioName == normalizedCurrentFileName
        }) {
            print("✅ Matched lyric by audioFileName: \(byFileName.title)")
            return byFileName
        }

        let normalizedTrackTitle = currentTrack.title.normalized
            .replacingOccurrences(of: #"^\d+\s*"#, with: "", options: .regularExpression)
        print("🎧 Normalized title for fallback: '\(normalizedTrackTitle)'")

        for lyric in allLyrics {
            let normalizedLyricTitle = lyric.title.normalized
                .replacingOccurrences(of: #"^\d+\s*"#, with: "", options: .regularExpression)
            print("🔍 Checking lyric title: '\(lyric.title)' → normalized: '\(normalizedLyricTitle)'")

            if normalizedLyricTitle == normalizedTrackTitle {
                print("✅ Matched lyric by title: \(lyric.title)")
                return lyric
            }
        }

        print("⚠️ No matching lyric found for: '\(normalizedTrackTitle)'")
        return nil
    }

    private func addProgressBar(to cell: UITableViewCell, for item: ServiceItem) {
        removeProgressBar(from: cell)
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tag = 99
        cell.contentView.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        if let current = AudioPlayerManager.shared.currentTrack,
           current.fileName == item.fileName {
            let duration = AudioPlayerManager.shared.duration
            let time = AudioPlayerManager.shared.currentTime
            if duration > 0 {
                progressView.progress = Float(time / duration)
            }
        }
    }

    private func removeProgressBar(from cell: UITableViewCell) {
        cell.contentView.subviews.filter { $0.tag == 99 }.forEach { $0.removeFromSuperview() }
    }

    private func startPlaybackProgressTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    // Notification handler must be inside the class; reload safely on main.
    @objc private func handleServiceItemsUpdated() {
        guard !tableView.isEditing else { return }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// Keep filename helpers separate from controller logic.
extension String {
    var cleanedWhitespace: String {
        let whitespaceSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{00A0}"))
        return self.trimmingCharacters(in: whitespaceSet)
    }
    var normalizedFilename: String {
        return cleanedWhitespace.lowercased().precomposedStringWithCanonicalMapping
    }
}
