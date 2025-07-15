import UIKit

extension Notification.Name {
    static let AudioPlayerTrackChanged = Notification.Name("AudioPlayerTrackChanged")
}

class ServiceViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let segmentedControl = UISegmentedControl(items: ["Service", "Details", "Booklet"])
    private let tableView = UITableView()
    private var lastTappedIndexPath: IndexPath?
    private var highlightedFlashIndex: IndexPath?
    private var playbackTimer: Timer?
    private let miniPlayerVC = MiniPlayerContainerViewController()
    private var miniPlayerHeightConstraint: NSLayoutConstraint!
    private let containerView = UIView()
    private let bookletFormVC = BookletInfoFormViewController()
    private let bookletGeneratorVC = PDFBookletPreviewViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        providesPresentationContextTransitionStyle = true
        
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )


        setupMiniPlayer()
        setupContainerView()
        setupTableView()
        setupBookletFormView()
        setupBookletGeneratorView()
        addDefaultWelcomeAndFarewell()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackChange),
            name: .AudioPlayerTrackChanged,
            object: nil
        )
        startPlaybackProgressTimer()
        
    }
    
    private func startPlaybackProgressTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AudioPlayerTrackChanged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        MiniPlayerManager.shared.playerView = miniPlayerVC.playerView
        MiniPlayerManager.shared.setupCallbacks(for: miniPlayerVC.playerView)
        MiniPlayerManager.shared.syncPlayerUI()
        tableView.reloadData()
    }

    
    private func setupNavigationBar() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        segmentedControl.backgroundColor = .tertiarySystemGroupedBackground
        segmentedControl.selectedSegmentTintColor = .white
        segmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.systemBlue
        ], for: .normal)
        segmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.label
        ], for: .selected)
        
        navigationItem.titleView = segmentedControl
        
        // Let BaseViewController handle login/logout button
        
    }
    private func setupMiniPlayer() {
        addChild(miniPlayerVC)
        view.addSubview(miniPlayerVC.view)
        miniPlayerVC.didMove(toParent: self)
        
        miniPlayerVC.view.translatesAutoresizingMaskIntoConstraints = false
        miniPlayerVC.view.backgroundColor = .systemGray6
        
        miniPlayerHeightConstraint = miniPlayerVC.view.heightAnchor.constraint(equalToConstant: 250)
        
        NSLayoutConstraint.activate([
            miniPlayerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            miniPlayerHeightConstraint
        ])
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.separatorInset = .zero
        tableView.isEditing = false
        tableView.allowsSelectionDuringEditing = true
        
        containerView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: miniPlayerVC.view.topAnchor)
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
        let index = sender.selectedSegmentIndex

        tableView.isHidden = index != 0
        bookletFormVC.view.isHidden = index != 1
        bookletGeneratorVC.view.isHidden = index != 2
        miniPlayerVC.view.isHidden = index != 0

        miniPlayerHeightConstraint.constant = index == 0 ? 250 : 0

        navigationItem.leftBarButtonItem = index == 0
            ? UIBarButtonItem(title: tableView.isEditing ? "Done" : "Edit", style: .plain, target: self, action: #selector(editButtonTapped))
            : nil

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    
    
    @objc private func editButtonTapped() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        navigationItem.leftBarButtonItem?.title = tableView.isEditing ? "Done" : "Edit"
    }


    
    @objc private func handleTrackChange() {
        if let current = AudioPlayerManager.shared.currentTrack {
            MiniPlayerManager.shared.updateNowPlayingTrack(current.title)
        } else {
            MiniPlayerManager.shared.clearTrackText()
        }
        tableView.reloadData()
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = ServiceOrderManager.shared.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let isPlaying = item.fileName != nil && item.fileName == AudioPlayerManager.shared.currentTrack?.fileName
        
        cell.textLabel?.text = "• \(item.title) (\(item.type.rawValue.capitalized))"
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .none
        cell.selectionStyle = .none
        
        if isPlaying {
            addProgressBar(to: cell, for: item)
        } else {
            removeProgressBar(from: cell)
        }
        
        if indexPath == highlightedFlashIndex {
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.35)
        } else if indexPath == lastTappedIndexPath {
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.25)
        } else {
            cell.backgroundColor = .clear
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        ServiceOrderManager.shared.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            ServiceOrderManager.shared.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    private func addDefaultWelcomeAndFarewell() {
        // Optional seeds
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastTappedIndexPath = indexPath
        let item = ServiceOrderManager.shared.items[indexPath.row]

        if [.song, .background, .music].contains(item.type), let fileName = item.fileName {
            let allSongs = SharedLibraryManager.shared.allSongs
            if let song = allSongs.first(where: { $0.fileName == fileName }) {
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
            return
        }

        if (item.type == .reading || item.type == .customReading), let text = item.customText {
            let preview = ReadingPreviewViewController(title: item.title, text: text)
            navigationController?.pushViewController(preview, animated: true)
            tableView.reloadData()
            return
        }

        print("❓ Selected item not playable or readable")
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ServiceOrderManager.shared.items.count
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
            
            guard duration > 0 else { return }
            progressView.progress = Float(time / duration)
        }

    }

    private func removeProgressBar(from cell: UITableViewCell) {
        cell.contentView.subviews.filter { $0.tag == 99 }.forEach { $0.removeFromSuperview() }
    }

}
