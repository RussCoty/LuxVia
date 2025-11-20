//
//  ImageManagerViewController.swift
//  LuxVia
//
//  Created on 16/11/2025.
//

import UIKit
import PhotosUI
import AVFoundation
import AVKit
import MediaPlayer

class ImageManagerViewController: BaseViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let segmentedControl = UISegmentedControl(items: ["By Playlist", "All Media"])
    private var playlists: [SlideshowPlaylist] = []
    private var allMedia: [SlideItem] = []
    
    // AirPlay controls
    private let airplayControlsContainer = UIView()
    private let previewImageView = UIImageView() // Mini monitor
    private let previewLabel = UILabel()
    private let airplayButton = UIButton(type: .system)
    private var routePickerView: AVRoutePickerView? // AirPlay picker
    private let playButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private var selectedPlaylistForAirPlay: SlideshowPlaylist?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Image Manager"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupSegmentedControl()
        setupAirPlayControls()
        setupTableView()
        loadData()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        updateAirPlayControls()
        
        // Check screen count periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.checkAirPlayConnection()
        }
    }
    
    private func checkAirPlayConnection() {
        let screenCount = UIScreen.screens.count
        print("🖥️ Screen check: \(screenCount) screen(s) available")
        
        if screenCount > 1 {
            statusLabel.text = "✅ AirPlay connected!"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Not connected"
            statusLabel.textColor = .secondaryLabel
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        // Add button
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addMediaTapped)
        )
        
        // Info button
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(infoTapped)
        )
        
        navigationItem.rightBarButtonItems = [addButton, infoButton]
    }
    
    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupAirPlayControls() {
        airplayControlsContainer.backgroundColor = .secondarySystemBackground
        airplayControlsContainer.layer.cornerRadius = 12
        airplayControlsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(airplayControlsContainer)
        
        // Mini preview monitor
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.backgroundColor = .black
        previewImageView.layer.cornerRadius = 8
        previewImageView.layer.borderWidth = 2
        previewImageView.layer.borderColor = UIColor.systemGray4.cgColor
        previewImageView.clipsToBounds = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        airplayControlsContainer.addSubview(previewImageView)
        
        // Preview label
        previewLabel.text = "Slideshow Preview"
        previewLabel.textAlignment = .center
        previewLabel.font = .systemFont(ofSize: 11, weight: .medium)
        previewLabel.textColor = .secondaryLabel
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        airplayControlsContainer.addSubview(previewLabel)
        
        // Official Apple AVRoutePickerView - THE primary AirPlay button
        let routePicker = AVRoutePickerView()
        routePicker.tintColor = .systemBlue
        routePicker.activeTintColor = .systemBlue
        routePicker.prioritizesVideoDevices = true
        routePicker.backgroundColor = .clear
        routePicker.translatesAutoresizingMaskIntoConstraints = false
        routePickerView = routePicker
        airplayControlsContainer.addSubview(routePicker)
        
        // Label below the official button
        let airplayLabel = UILabel()
        airplayLabel.text = "Tap to connect AirPlay"
        airplayLabel.textAlignment = .center
        airplayLabel.font = .systemFont(ofSize: 13, weight: .medium)
        airplayLabel.textColor = .label
        airplayLabel.translatesAutoresizingMaskIntoConstraints = false
        airplayControlsContainer.addSubview(airplayLabel)
        
        // Status label
        statusLabel.text = "Not connected"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 11, weight: .regular)
        statusLabel.numberOfLines = 2
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        airplayControlsContainer.addSubview(statusLabel)
        
        // Play button
        playButton.setTitle("▶️ Start Slideshow", for: .normal)
        playButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        playButton.addTarget(self, action: #selector(playAirPlayTapped), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        airplayControlsContainer.addSubview(playButton)
        
        // Stop button
        stopButton.setTitle("⏹ Stop", for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        stopButton.setTitleColor(.systemRed, for: .normal)
        stopButton.addTarget(self, action: #selector(stopAirPlayTapped), for: .touchUpInside)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        airplayControlsContainer.addSubview(stopButton)
        
        NSLayoutConstraint.activate([
            airplayControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            airplayControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            airplayControlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            airplayControlsContainer.heightAnchor.constraint(equalToConstant: 230),
            
            // Preview at top
            previewImageView.topAnchor.constraint(equalTo: airplayControlsContainer.topAnchor, constant: 8),
            previewImageView.centerXAnchor.constraint(equalTo: airplayControlsContainer.centerXAnchor),
            previewImageView.widthAnchor.constraint(equalToConstant: 120),
            previewImageView.heightAnchor.constraint(equalToConstant: 80),
            
            previewLabel.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 2),
            previewLabel.centerXAnchor.constraint(equalTo: airplayControlsContainer.centerXAnchor),
            
            // Official AirPlay button (AVRoutePickerView) - highly visible
            routePicker.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 12),
            routePicker.centerXAnchor.constraint(equalTo: airplayControlsContainer.centerXAnchor),
            routePicker.widthAnchor.constraint(equalToConstant: 50),
            routePicker.heightAnchor.constraint(equalToConstant: 50),
            
            airplayLabel.topAnchor.constraint(equalTo: routePicker.bottomAnchor, constant: 4),
            airplayLabel.centerXAnchor.constraint(equalTo: airplayControlsContainer.centerXAnchor),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: airplayLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: airplayControlsContainer.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: airplayControlsContainer.trailingAnchor, constant: -16),
            
            // Control buttons at bottom
            playButton.bottomAnchor.constraint(equalTo: airplayControlsContainer.bottomAnchor, constant: -12),
            playButton.leadingAnchor.constraint(equalTo: airplayControlsContainer.leadingAnchor, constant: 16),
            
            stopButton.bottomAnchor.constraint(equalTo: airplayControlsContainer.bottomAnchor, constant: -12),
            stopButton.trailingAnchor.constraint(equalTo: airplayControlsContainer.trailingAnchor, constant: -16)
        ])
        
        updateAirPlayControls()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(slideshowDidUpdate),
            name: SlideshowManager.slideshowDidUpdateSlide,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(slideshowDidStop),
            name: SlideshowManager.slideshowDidStop,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(slideshowDidStart),
            name: SlideshowManager.slideshowDidStart,
            object: nil
        )
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MediaItemCell.self, forCellReuseIdentifier: "MediaCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: airplayControlsContainer.topAnchor, constant: -8)
        ])
    }
    
    // MARK: - Data
    private func loadData() {
        playlists = ImageManager.shared.getAllPlaylists()
        allMedia = ImageManager.shared.getAllMediaItems()
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        tableView.reloadData()
    }
    
    @objc private func addMediaTapped() {
        let alert = UIAlertController(title: "Add Media", message: "Choose an option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Add to New Playlist", style: .default) { [weak self] _ in
            self?.createNewPlaylist()
        })
        
        if !playlists.isEmpty {
            alert.addAction(UIAlertAction(title: "Add to Existing Playlist", style: .default) { [weak self] _ in
                self?.selectPlaylistToAddMedia()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(alert, animated: true)
    }
    
    @objc private func infoTapped() {
        let alert = UIAlertController(
            title: "Image Manager",
            message: """
            Manage all your slideshow images and videos in one place.
            
            • View by playlist or see all media
            • Add new images/videos from your library
            • Create and organize playlists
            • Delete media you no longer need
            • Tap a playlist header to start AirPlay slideshow
            
            Media added here is used in the Slideshow tab for memorial displays.
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func playAirPlayTapped() {
        guard let playlist = selectedPlaylistForAirPlay else {
            let alert = UIAlertController(
                title: "No Playlist Selected",
                message: "Please tap on a playlist header to select it for AirPlay display.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        guard !playlist.slides.isEmpty else {
            let alert = UIAlertController(
                title: "Empty Playlist",
                message: "This playlist has no images or videos. Add some media first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Check if AirPlay is connected
        let screenCount = UIScreen.screens.count
        print("🖥️ Screens available: \(screenCount)")
        
        if screenCount == 1 {
            let alert = UIAlertController(
                title: "AirPlay Not Connected",
                message: "Please connect to an AirPlay device first using the '📡 Connect to AirPlay' button above, then try playing the slideshow.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Enable loop mode for continuous display
        var loopedPlaylist = playlist
        loopedPlaylist.settings.loopEnabled = true
        SlideshowManager.shared.updatePlaylist(loopedPlaylist)
        
        // Start the slideshow
        SlideshowManager.shared.startSlideshow(playlist: loopedPlaylist)
        updateAirPlayControls()
    }
    
    @objc private func stopAirPlayTapped() {
        SlideshowManager.shared.stopSlideshow()
        updateAirPlayControls()
    }
    
    @objc private func slideshowDidStart() {
        updateAirPlayControls()
    }
    
    @objc private func slideshowDidUpdate(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let index = userInfo["index"] as? Int,
              let slide = userInfo["slide"] as? SlideItem else { return }
        
        if let playlist = SlideshowManager.shared.getCurrentPlaylist() {
            statusLabel.text = "Playing: \(playlist.name) - Slide \(index + 1) of \(playlist.slides.count)"
        }
        
        // Update mini preview monitor
        updatePreviewMonitor(with: slide)
    }
    
    @objc private func slideshowDidStop() {
        updateAirPlayControls()
        // Clear preview
        previewImageView.image = nil
        previewLabel.text = "Slideshow Preview"
    }
    
    private func updatePreviewMonitor(with slide: SlideItem) {
        let fileURL = ImageManager.shared.getMediaURL(for: slide.fileName)
        
        if slide.type == .image {
            // Display image in preview
            if let image = UIImage(contentsOfFile: fileURL.path) {
                previewImageView.image = image
                previewLabel.text = "Now Playing: \(slide.fileName.prefix(20))..."
            }
        } else {
            // Generate video thumbnail for preview
            let asset = AVAsset(url: fileURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                let time = CMTime(seconds: 1, preferredTimescale: 60)
                if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                    DispatchQueue.main.async {
                        self.previewImageView.image = UIImage(cgImage: cgImage)
                        self.previewLabel.text = "Now Playing: \(slide.fileName.prefix(20))..."
                    }
                }
            }
        }
    }
    
    private func updateAirPlayControls() {
        let isPlaying = SlideshowManager.shared.isCurrentlyPlaying()
        
        if isPlaying {
            if let currentPlaylist = SlideshowManager.shared.getCurrentPlaylist() {
                let currentIndex = SlideshowManager.shared.getCurrentSlideIndex()
                statusLabel.text = "▶️ \(currentPlaylist.name) - Slide \(currentIndex + 1)/\(currentPlaylist.slides.count)"
            } else {
                statusLabel.text = "▶️ Slideshow playing on AirPlay"
            }
            airplayButton.isEnabled = false
            playButton.isEnabled = false
            stopButton.isEnabled = true
        } else {
            if let selected = selectedPlaylistForAirPlay {
                statusLabel.text = "✓ Ready: \(selected.name) (\(selected.slides.count) items)"
            } else {
                statusLabel.text = "Connect to AirPlay, then select a playlist below"
            }
            airplayButton.isEnabled = true
            playButton.isEnabled = selectedPlaylistForAirPlay != nil
            stopButton.isEnabled = false
        }
    }
    
    private func createNewPlaylist() {
        let alert = UIAlertController(title: "New Playlist", message: "Enter a name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g., Memorial Photos"
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let playlist = ImageManager.shared.createPlaylist(name: name)
            self?.presentMediaPicker(for: playlist)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func selectPlaylistToAddMedia() {
        let alert = UIAlertController(title: "Select Playlist", message: nil, preferredStyle: .actionSheet)
        
        for playlist in playlists {
            alert.addAction(UIAlertAction(title: playlist.name, style: .default) { [weak self] _ in
                self?.presentMediaPicker(for: playlist)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(alert, animated: true)
    }
    
    private func presentMediaPicker(for playlist: SlideshowPlaylist) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 0
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.view.tag = playlists.firstIndex(where: { $0.id == playlist.id }) ?? 0
        present(picker, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension ImageManagerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return playlists.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return playlists[section].slides.count
        } else {
            return allMedia.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if segmentedControl.selectedSegmentIndex == 0 {
            let playlist = playlists[section]
            let isSelected = selectedPlaylistForAirPlay?.id == playlist.id ? "✓ " : ""
            return "\(isSelected)\(playlist.name) (\(playlist.slides.count) items)"
        } else {
            return "All Media (\(allMedia.count) items)"
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard segmentedControl.selectedSegmentIndex == 0 else { return nil }
        
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let playlist = playlists[section]
        let isSelected = selectedPlaylistForAirPlay?.id == playlist.id
        label.text = (isSelected ? "✓ " : "") + "\(playlist.name) (\(playlist.slides.count) items)"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = isSelected ? .systemBlue : .secondaryLabel
        headerView.addSubview(label)
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(isSelected ? "Selected for AirPlay" : "Select for AirPlay", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.tag = section
        button.addTarget(self, action: #selector(selectPlaylistForAirPlay(_:)), for: .touchUpInside)
        headerView.addSubview(button)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            button.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return segmentedControl.selectedSegmentIndex == 0 ? 44 : 28
    }
    
    @objc private func selectPlaylistForAirPlay(_ sender: UIButton) {
        let section = sender.tag
        let playlist = playlists[section]
        
        if selectedPlaylistForAirPlay?.id == playlist.id {
            selectedPlaylistForAirPlay = nil
        } else {
            selectedPlaylistForAirPlay = playlist
        }
        
        tableView.reloadData()
        updateAirPlayControls()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MediaCell", for: indexPath) as! MediaItemCell
        
        let slide: SlideItem
        if segmentedControl.selectedSegmentIndex == 0 {
            slide = playlists[indexPath.section].slides[indexPath.row]
        } else {
            slide = allMedia[indexPath.row]
        }
        
        cell.configure(with: slide)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if segmentedControl.selectedSegmentIndex == 0 {
                // Delete from specific playlist
                var playlist = playlists[indexPath.section]
                let slide = playlist.slides[indexPath.row]
                
                // Ask if they want to delete the file too
                let alert = UIAlertController(
                    title: "Delete Media",
                    message: "Delete from playlist only, or delete the file completely?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Remove from Playlist", style: .default) { [weak self] _ in
                    playlist.slides.remove(at: indexPath.row)
                    SlideshowManager.shared.updatePlaylist(playlist)
                    self?.loadData()
                })
                
                alert.addAction(UIAlertAction(title: "Delete File", style: .destructive) { [weak self] _ in
                    ImageManager.shared.deleteMediaFile(fileName: slide.fileName)
                    playlist.slides.remove(at: indexPath.row)
                    SlideshowManager.shared.updatePlaylist(playlist)
                    self?.loadData()
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
            } else {
                // Delete from all media view
                let slide = allMedia[indexPath.row]
                
                let alert = UIAlertController(
                    title: "Delete Media",
                    message: "This will remove the file from all playlists. Continue?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                    ImageManager.shared.deleteMediaFile(fileName: slide.fileName)
                    
                    // Remove from all playlists
                    for var playlist in self?.playlists ?? [] {
                        playlist.slides.removeAll { $0.fileName == slide.fileName }
                        SlideshowManager.shared.updatePlaylist(playlist)
                    }
                    
                    self?.loadData()
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let slide: SlideItem
        if segmentedControl.selectedSegmentIndex == 0 {
            slide = playlists[indexPath.section].slides[indexPath.row]
        } else {
            slide = allMedia[indexPath.row]
        }
        
        // Show preview
        let previewVC = MediaPreviewViewController(slide: slide)
        navigationController?.pushViewController(previewVC, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ImageManagerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let playlistIndex = picker.view.tag
        picker.dismiss(animated: true)
        
        guard !results.isEmpty, playlistIndex < playlists.count else { return }
        var playlist = playlists[playlistIndex]
        
        for result in results {
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    guard let data = data else { return }
                    
                    let fileName = "\(UUID().uuidString).jpg"
                    if ImageManager.shared.saveMediaFile(data: data, fileName: fileName) != nil {
                        let slide = SlideItem(
                            fileName: fileName,
                            type: .image,
                            duration: playlist.settings.defaultImageDuration,
                            order: playlist.slides.count
                        )
                        
                        DispatchQueue.main.async {
                            playlist = ImageManager.shared.addMediaToPlaylist(playlist, slide: slide)
                            self.loadData()
                        }
                    }
                }
            } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    guard let url = url, let data = try? Data(contentsOf: url) else { return }
                    
                    let fileName = "\(UUID().uuidString).mp4"
                    if ImageManager.shared.saveMediaFile(data: data, fileName: fileName) != nil {
                        let asset = AVAsset(url: url)
                        let duration = CMTimeGetSeconds(asset.duration)
                        
                        let slide = SlideItem(
                            fileName: fileName,
                            type: .video,
                            duration: duration,
                            order: playlist.slides.count
                        )
                        
                        DispatchQueue.main.async {
                            playlist = ImageManager.shared.addMediaToPlaylist(playlist, slide: slide)
                            self.loadData()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - MediaItemCell
class MediaItemCell: UITableViewCell {
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let durationLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.backgroundColor = .systemGray5
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        typeLabel.font = .systemFont(ofSize: 14)
        typeLabel.textColor = .systemBlue
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(typeLabel)
        
        durationLabel.font = .systemFont(ofSize: 14)
        durationLabel.textColor = .secondaryLabel
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            typeLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            typeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            durationLabel.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 8),
            durationLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor)
        ])
    }
    
    func configure(with slide: SlideItem) {
        titleLabel.text = slide.fileName
        typeLabel.text = slide.type == .image ? "📷 Image" : "🎬 Video"
        durationLabel.text = String(format: "%.1fs", slide.duration)
        
        let fileURL = ImageManager.shared.getMediaURL(for: slide.fileName)
        
        if slide.type == .image {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                thumbnailImageView.image = image
            }
        } else {
            let asset = AVAsset(url: fileURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                thumbnailImageView.image = UIImage(cgImage: cgImage)
            }
        }
    }
}

// MARK: - MediaPreviewViewController
class MediaPreviewViewController: UIViewController {
    private let slide: SlideItem
    private let imageView = UIImageView()
    private var playerViewController: AVPlayerViewController?
    
    init(slide: SlideItem) {
        self.slide = slide
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = slide.fileName
        view.backgroundColor = .black
        
        let fileURL = ImageManager.shared.getMediaURL(for: slide.fileName)
        
        if slide.type == .image {
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            imageView.image = UIImage(contentsOfFile: fileURL.path)
        } else {
            let player = AVPlayer(url: fileURL)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            playerViewController = playerVC
            
            addChild(playerVC)
            view.addSubview(playerVC.view)
            playerVC.view.frame = view.bounds
            playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            playerVC.didMove(toParent: self)
            
            player.play()
        }
    }
}
