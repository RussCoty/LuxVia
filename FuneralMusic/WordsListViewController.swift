import UIKit

class WordsListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    deinit {
        // If you ever reintroduce observers
        NotificationCenter.default.removeObserver(self)
    }

    private let segmentedControl = UISegmentedControl(items: ["Readings", "Lyrics", "Custom"])
    private let tableView = UITableView()
    private var customVC: CustomReadingsViewController?

    private var lyrics: [LyricEntry] = []
    private var filteredLyrics: [LyricEntry] = []

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

        lyrics = LyricsSyncManager.shared.loadCachedLyrics()
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        filteredLyrics = lyrics

        setupNavigationBar()
        setupTableView()
        
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
        case 1:
            filteredLyrics = lyrics.enumerated().compactMap { $0.offset % 2 == 0 ? $0.element : nil }
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
            filteredLyrics = lyrics
            tableView.isHidden = false
            tableView.reloadData()
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
