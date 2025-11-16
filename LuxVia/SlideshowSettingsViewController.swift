//
//  SlideshowSettingsViewController.swift
//  LuxVia
//
//  Created on 16/11/2025.
//

import UIKit

class SlideshowSettingsViewController: UIViewController {
    
    // MARK: - Properties
    private var playlist: SlideshowPlaylist
    var onSave: ((SlideshowPlaylist) -> Void)?
    
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let loopSwitch = UISwitch()
    private let shuffleSwitch = UISwitch()
    private let durationSlider = UISlider()
    private let durationLabel = UILabel()
    private let transitionPicker = UISegmentedControl(items: ["Fade", "Dissolve", "Slide L", "Slide R", "None"])
    
    // MARK: - Initialization
    init(playlist: SlideshowPlaylist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Slideshow Settings"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupTableView()
        loadSettings()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadSettings() {
        loopSwitch.isOn = playlist.settings.loopEnabled
        shuffleSwitch.isOn = playlist.settings.shuffleEnabled
        durationSlider.value = Float(playlist.settings.defaultImageDuration)
        durationLabel.text = String(format: "%.1f seconds", playlist.settings.defaultImageDuration)
        
        switch playlist.settings.transitionStyle {
        case .fade: transitionPicker.selectedSegmentIndex = 0
        case .dissolve: transitionPicker.selectedSegmentIndex = 1
        case .slideLeft: transitionPicker.selectedSegmentIndex = 2
        case .slideRight: transitionPicker.selectedSegmentIndex = 3
        case .none: transitionPicker.selectedSegmentIndex = 4
        }
        
        loopSwitch.addTarget(self, action: #selector(settingChanged), for: .valueChanged)
        shuffleSwitch.addTarget(self, action: #selector(settingChanged), for: .valueChanged)
        durationSlider.addTarget(self, action: #selector(durationChanged), for: .valueChanged)
        transitionPicker.addTarget(self, action: #selector(settingChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        // Update playlist settings
        let transitionStyle: SlideshowSettings.TransitionStyle
        switch transitionPicker.selectedSegmentIndex {
        case 0: transitionStyle = .fade
        case 1: transitionStyle = .dissolve
        case 2: transitionStyle = .slideLeft
        case 3: transitionStyle = .slideRight
        default: transitionStyle = .none
        }
        
        let newSettings = SlideshowSettings(
            loopEnabled: loopSwitch.isOn,
            transitionStyle: transitionStyle,
            defaultImageDuration: TimeInterval(durationSlider.value),
            shuffleEnabled: shuffleSwitch.isOn
        )
        
        playlist.settings = newSettings
        onSave?(playlist)
        dismiss(animated: true)
    }
    
    @objc private func settingChanged() {
        // Settings are saved when Save is tapped
    }
    
    @objc private func durationChanged() {
        durationLabel.text = String(format: "%.1f seconds", durationSlider.value)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension SlideshowSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Loop and Shuffle
        case 1: return 1 // Duration
        case 2: return 1 // Transition
        case 3: return 1 // Playlist name
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Playback"
        case 1: return "Image Duration"
        case 2: return "Transition Effect"
        case 3: return "Playlist Info"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        
        // Clear previous accessories
        cell.accessoryView = nil
        cell.textLabel?.text = nil
        
        switch indexPath.section {
        case 0: // Playback
            if indexPath.row == 0 {
                cell.textLabel?.text = "Loop Slideshow"
                cell.accessoryView = loopSwitch
            } else {
                cell.textLabel?.text = "Shuffle"
                cell.accessoryView = shuffleSwitch
            }
            
        case 1: // Duration
            cell.textLabel?.text = "Default Duration"
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 12
            
            durationSlider.minimumValue = 1.0
            durationSlider.maximumValue = 30.0
            durationSlider.translatesAutoresizingMaskIntoConstraints = false
            durationSlider.widthAnchor.constraint(equalToConstant: 150).isActive = true
            
            durationLabel.font = .systemFont(ofSize: 14)
            durationLabel.textColor = .secondaryLabel
            
            stackView.addArrangedSubview(durationSlider)
            stackView.addArrangedSubview(durationLabel)
            
            cell.accessoryView = stackView
            
        case 2: // Transition
            cell.textLabel?.text = "Transition"
            cell.contentView.addSubview(transitionPicker)
            transitionPicker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                transitionPicker.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                transitionPicker.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                transitionPicker.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                transitionPicker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            
        case 3: // Playlist info
            cell.textLabel?.text = "Playlist: \(playlist.name)"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return 60
        }
        return 44
    }
}
