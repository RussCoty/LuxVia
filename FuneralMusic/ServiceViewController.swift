import UIKit
import Foundation
import WebKit

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
        tableView.allowsSelectionDuringEditing = true

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
    }

    @objc private func editButtonTapped() {
        let isEditing = tableView.isEditing
        tableView.setEditing(!isEditing, animated: true)
        navigationItem.leftBarButtonItem?.title = !isEditing ? "Done" : "Edit"
        isEditing ? playbackTimer?.invalidate() : startPlaybackProgressTimer()
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

        cell.textLabel?.text = "• \(item.title) (\(item.type.rawValue.capitalized))"
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .none
        cell.selectionStyle = .none

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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastTappedIndexPath = indexPath
        guard let item = item(for: indexPath) else { return }

        if item.type == .reading || item.type == .customReading,
           let text = item.customText {
            logMiniPlayer("didSelectRowAt (reading)", visible: false)
            if !UIApplication.isServiceTabActive() {
                MiniPlayerManager.shared.setVisible(false)
            }
            let preview = ReadingPreviewViewController(title: item.title, text: text)
            navigationController?.pushViewController(preview, animated: true)
            tableView.reloadData()
            return
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

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView,
                   moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {
        guard let fromItem = item(for: sourceIndexPath),
              let toItem = item(for: destinationIndexPath),
              let fromIndex = ServiceOrderManager.shared.items.firstIndex(where: { $0.id == fromItem.id }),
              let toIndex = ServiceOrderManager.shared.items.firstIndex(where: { $0.id == toItem.id }) else { return }

        ServiceOrderManager.shared.move(from: fromIndex, to: toIndex)
        ServiceOrderManager.shared.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            tableView.reloadData()
        }
    }

    func lyricForPlayingTrack() -> LyricEntry? {
        guard let currentTrack = AudioPlayerManager.shared.currentTrack else { return nil }
        return SharedLibraryManager.shared.allReadings.first {
            $0.title.normalized == currentTrack.title.normalized
        }
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

}
