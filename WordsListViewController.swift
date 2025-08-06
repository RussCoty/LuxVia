import UIKit

class WordsListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    deinit {
        // If you ever reintroduce observers
        NotificationCenter.default.removeObserver(self)
    }

    private let segmentedControl = UISegmentedControl(items: ["Readings", "Lyrics", "Custom"])
    private let tableView = UITableView()
    private var customVC: CustomReadingsViewController?

    //private var lyrics: [Lyric] = []
    //private var filteredLyrics: [Lyric] = []
    private var lyrics: [Lyric] = []
    private var readings: [Lyric] = []
    private var lyricOnly: [Lyric] = []
    private var filteredLyrics: [Lyric] = []

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

        // Let BaseViewController handle login/logout button
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
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


    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredLyrics.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = filteredLyrics[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = entry.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = filteredLyrics[indexPath.row]
        let detailVC = LyricsDetailViewController(entry: entry)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    



}
