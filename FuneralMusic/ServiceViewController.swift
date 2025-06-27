// File: ServiceViewController.swift

import UIKit

class ServiceViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let segmentedControl = UISegmentedControl(items: ["Service", "Details", "Booklet"])
    private let tableView = UITableView()
    private var selectedIndex: IndexPath?
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
        setupMiniPlayer()
        setupContainerView()
        setupTableView()
        setupBookletFormView()
        setupBookletGeneratorView()
        addDefaultWelcomeAndFarewell()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(handleLogout)
        )
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
        tableView.setEditing(true, animated: false)
        tableView.allowsSelectionDuringEditing = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.separatorInset = .zero

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

    @objc private func handleLogout() {
        AuthManager.shared.logout()
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex

        tableView.isHidden = index != 0
        bookletFormVC.view.isHidden = index != 1
        bookletGeneratorVC.view.isHidden = index != 2
        miniPlayerVC.view.isHidden = index != 0

        miniPlayerHeightConstraint.constant = index == 0 ? 250 : 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ServiceOrderManager.shared.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = ServiceOrderManager.shared.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = "• \(item.title) (\(item.type.rawValue.capitalized))"
        cell.textLabel?.numberOfLines = 0
        cell.backgroundColor = (indexPath == selectedIndex) ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
        cell.accessoryType = .none
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ServiceOrderManager.shared.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        ServiceOrderManager.shared.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    private func addDefaultWelcomeAndFarewell() {
        // optional seed items
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = ServiceOrderManager.shared.items[indexPath.row]
        print("Selected Row: \(indexPath.row) - \(item.title) [\(item.type.rawValue)]")
        print("item.type = \(item.type.rawValue)")
        print("item.fileName = \(item.fileName ?? "nil")")

        if selectedIndex == indexPath {
            print("Deselected same row")
            selectedIndex = nil
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }

        selectedIndex = indexPath
        tableView.reloadData()

        if [.song, .background, .music].contains(item.type), let fileName = item.fileName {
            print("Looking for exact match for fileName: \(fileName)")

            if let song = SharedLibraryManager.shared.allSongs.first(where: { $0.fileName == fileName }) {
                print("Found SongEntry: \(song.title)")
                AudioPlayerManager.shared.cueTrack(song, source: .library)

                PlayerControlsView.shared = miniPlayerVC.playerView
                AudioPlayerManager.shared.cueTrack(song, source: .library)
                PlayerControlsView.shared?.updateCuedTrackText(song.title)
            } else {
                print("SongEntry not found in library for: \(fileName)")
            }
            return
        }

        guard (item.type == .reading || item.type == .customReading),
              let text = item.customText else {
            print("Not a reading or missing text")
            return
        }

        if presentedViewController is ReadingPreviewViewController {
            print("Preview already presented")
            return
        }

        print("Presenting ReadingPreviewViewController with title: \(item.title)")
        let preview = ReadingPreviewViewController(title: item.title, text: text)
        navigationController?.pushViewController(preview, animated: true)
    }
}
