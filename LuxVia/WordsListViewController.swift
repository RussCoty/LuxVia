import UIKit

class WordsListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // No collapsible logic needed
    deinit {
        // If you ever reintroduce observers
        NotificationCenter.default.removeObserver(self)
    }

    private let segmentedControl = UISegmentedControl(items: ["Readings", "Lyrics", "Custom"])
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var customVC: CustomReadingsViewController?

    //private var lyrics: [Lyric] = []
    //private var filteredLyrics: [Lyric] = []
    private var lyrics: [Lyric] = []
    private var readings: [Lyric] = []
    private var lyricOnly: [Lyric] = []
    private var filteredLyrics: [Lyric] = []
    private var readingsByCategory: [(category: String, readings: [Lyric])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue

        let allLyrics = CSVLyricsLoader.shared.loadLyrics()

            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

    lyrics = allLyrics
    readings = allLyrics.filter { $0.type == LyricType.reading }
    lyricOnly = allLyrics.filter { $0.type == LyricType.lyric }
    // Group readings by category
        let grouped = Dictionary(grouping: readings) { $0.category ?? "Other" }
        readingsByCategory = grouped.keys.sorted().map { (category) in
            (category, grouped[category] ?? [])
        }
        filteredLyrics = readings // Default to "Readings" tab

        setupNavigationBar()
        setupTableView()
        
        print("🎼 Total lyrics loaded: \(allLyrics.count)")
        print("📖 Readings count: \(readings.count)")
        print("🎤 Lyrics count: \(lyricOnly.count)")

        for reading in readings.prefix(5) {
            print("📖 \(reading.title) – \(reading.type)")
        }

        for lyric in lyricOnly.prefix(5) {
            print("🎤 \(lyric.title) – \(lyric.type)")
        }

    }


    private func setupNavigationBar() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl

        // Add help button
        let helpButton = UIBarButtonItem(
            image: UIImage(systemName: "questionmark.circle"),
            style: .plain,
            target: self,
            action: #selector(helpTapped)
        )
        navigationItem.rightBarButtonItem = helpButton

        // Let BaseViewController handle login/logout button
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    tableView.backgroundColor = .systemGray6
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        tableView.separatorStyle = .singleLine
        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = 44
    // style is set at initialization
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }



    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        customVC?.view.removeFromSuperview()
        customVC?.removeFromParent()

        switch sender.selectedSegmentIndex {
        case 0:
            filteredLyrics = readings
            tableView.isHidden = false
            tableView.reloadData()
        case 1:
            filteredLyrics = lyricOnly
            tableView.isHidden = false
            tableView.reloadData()
        case 2:
            tableView.isHidden = true
            let custom = CustomReadingsViewController()
            addChild(custom)
            view.addSubview(custom.view)
            custom.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                custom.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                custom.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                custom.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                custom.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            custom.didMove(toParent: self)
            self.customVC = custom
        default:
            break
        }
    }
    
    @objc private func helpTapped() {
        let alert = UIAlertController(title: "Help & Tours", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "App Tour", style: .default) { _ in
            self.presentAppTour()
        })
        
        alert.addAction(UIAlertAction(title: "Words & Readings Help", style: .default) { _ in
            self.showWordsHelp()
        })
        
        alert.addAction(UIAlertAction(title: "Custom Readings Guide", style: .default) { _ in
            self.showCustomReadingsGuide()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func showWordsHelp() {
        let helpVC = UIAlertController(
            title: "Words & Readings Help",
            message: """
            • Browse funeral readings and song lyrics
            • Readings: Traditional funeral texts and prayers
            • Lyrics: Words to funeral songs and hymns
            • Custom: Create and manage your own readings
            
            Tap any item to view the full text and add it to your service.
            """,
            preferredStyle: .alert
        )
        
        helpVC.addAction(UIAlertAction(title: "Got it", style: .default))
        present(helpVC, animated: true)
    }
    
    private func showCustomReadingsGuide() {
        let customVC = UIAlertController(
            title: "Custom Readings Guide",
            message: """
            1. Switch to the Custom tab
            2. Tap '+' to create a new reading
            3. Give your reading a title
            4. Write or paste your content
            5. Save to add it to your collection
            
            Custom readings can be personal messages, poems, or special texts.
            """,
            preferredStyle: .alert
        )
        
        customVC.addAction(UIAlertAction(title: "Show App Tour", style: .default) { _ in
            self.presentAppTour()
        })
        customVC.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(customVC, animated: true)
    }


    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return segmentedControl.selectedSegmentIndex == 0 ? readingsByCategory.count : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return readingsByCategory[section].readings.count
        } else {
            return filteredLyrics.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if segmentedControl.selectedSegmentIndex == 0 {
            return readingsByCategory[section].category
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let entry: Lyric
        if segmentedControl.selectedSegmentIndex == 0 {
            entry = readingsByCategory[indexPath.section].readings[indexPath.row]
        } else {
            entry = filteredLyrics[indexPath.row]
        }
        cell.textLabel?.text = entry.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry: Lyric
        if segmentedControl.selectedSegmentIndex == 0 {
            entry = readingsByCategory[indexPath.section].readings[indexPath.row]
        } else {
            entry = filteredLyrics[indexPath.row]
        }
        let detailVC = LyricsDetailViewController(entry: entry)
        navigationController?.pushViewController(detailVC, animated: true)
    }



}
