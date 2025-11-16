//
//  SlideshowViewController.swift
//  LuxVia
//
//  Created on 16/11/2025.
//

import UIKit
import AVFoundation
import PhotosUI

class SlideshowViewController: BaseViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let playlistPicker = UISegmentedControl()
    private var playlists: [SlideshowPlaylist] = []
    private var currentPlaylist: SlideshowPlaylist?
    
    private let controlsContainer = UIView()
    private let playButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    
    private let addMediaButton = UIButton(type: .system)
    private let newPlaylistButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Slideshow"
        view.backgroundColor = .systemBackground
        
        setupUI()
        loadPlaylists()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupUI() {
        setupToolbar()
        setupControlsContainer()
        setupTableView()
        updateControlsState()
    }
    
    private func setupToolbar() {
        // Add Media button
        addMediaButton.setTitle("Add Media", for: .normal)
        addMediaButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addMediaButton.addTarget(self, action: #selector(addMediaTapped), for: .touchUpInside)
        
        // New Playlist button
        newPlaylistButton.setTitle("New Playlist", for: .normal)
        newPlaylistButton.setImage(UIImage(systemName: "folder.badge.plus"), for: .normal)
        newPlaylistButton.addTarget(self, action: #selector(newPlaylistTapped), for: .touchUpInside)
        
        // Settings button
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [addMediaButton, newPlaylistButton, settingsButton])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupControlsContainer() {
        controlsContainer.backgroundColor = .secondarySystemBackground
        controlsContainer.layer.cornerRadius = 12
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsContainer)
        
        // Status label
        statusLabel.text = "No slideshow playing"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.addSubview(statusLabel)
        
        // Control buttons
        previousButton.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        
        nextButton.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        let buttonsStack = UIStackView(arrangedSubviews: [previousButton, playButton, stopButton, nextButton])
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .equalSpacing
        buttonsStack.spacing = 24
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.addSubview(buttonsStack)
        
        NSLayoutConstraint.activate([
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            controlsContainer.heightAnchor.constraint(equalToConstant: 120),
            
            statusLabel.topAnchor.constraint(equalTo: controlsContainer.topAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),
            
            buttonsStack.centerXAnchor.constraint(equalTo: controlsContainer.centerXAnchor),
            buttonsStack.bottomAnchor.constraint(equalTo: controlsContainer.bottomAnchor, constant: -20),
            buttonsStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SlideTableViewCell.self, forCellReuseIdentifier: "SlideCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: addMediaButton.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: controlsContainer.topAnchor, constant: -16)
        ])
    }
    
    private func setupObservers() {
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
    }
    
    // MARK: - Data Management
    private func loadPlaylists() {
        playlists = SlideshowManager.shared.getAllPlaylists()
        
        if playlists.isEmpty {
            // Create a default playlist
            let defaultPlaylist = SlideshowManager.shared.createPlaylist(name: "My Slideshow")
            playlists = [defaultPlaylist]
        }
        
        currentPlaylist = playlists.first
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func addMediaTapped() {
        let alert = UIAlertController(title: "Add Media", message: "Choose media type", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Add Images", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        })
        
        alert.addAction(UIAlertAction(title: "Add Videos", style: .default) { [weak self] _ in
            self?.presentVideoPicker()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0 // Allow multiple selection
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentVideoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 0 // Allow multiple selection
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func newPlaylistTapped() {
        let alert = UIAlertController(title: "New Playlist", message: "Enter playlist name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Playlist Name"
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let newPlaylist = SlideshowManager.shared.createPlaylist(name: name)
            self?.playlists.append(newPlaylist)
            self?.currentPlaylist = newPlaylist
            self?.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func settingsTapped() {
        guard var playlist = currentPlaylist else { return }
        
        let settingsVC = SlideshowSettingsViewController(playlist: playlist)
        settingsVC.onSave = { [weak self] updatedPlaylist in
            SlideshowManager.shared.updatePlaylist(updatedPlaylist)
            self?.currentPlaylist = updatedPlaylist
            self?.loadPlaylists()
        }
        
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    @objc private func playTapped() {
        guard let playlist = currentPlaylist else { return }
        
        if SlideshowManager.shared.isCurrentlyPlaying() {
            SlideshowManager.shared.pauseSlideshow()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            statusLabel.text = "Paused"
        } else {
            SlideshowManager.shared.startSlideshow(playlist: playlist)
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            statusLabel.text = "Playing on AirPlay"
        }
        updateControlsState()
    }
    
    @objc private func stopTapped() {
        SlideshowManager.shared.stopSlideshow()
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        statusLabel.text = "Stopped"
        updateControlsState()
    }
    
    @objc private func previousTapped() {
        SlideshowManager.shared.previousSlide()
    }
    
    @objc private func nextTapped() {
        SlideshowManager.shared.nextSlide()
    }
    
    @objc private func slideshowDidUpdate(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let index = userInfo["index"] as? Int,
              let slide = userInfo["slide"] as? SlideItem else { return }
        
        statusLabel.text = "Playing: \(slide.fileName) (\(index + 1) of \(currentPlaylist?.slides.count ?? 0))"
    }
    
    @objc private func slideshowDidStop(notification: Notification) {
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        statusLabel.text = "Slideshow ended"
        updateControlsState()
    }
    
    private func updateControlsState() {
        let isPlaying = SlideshowManager.shared.isCurrentlyPlaying()
        let hasSlides = (currentPlaylist?.slides.count ?? 0) > 0
        
        playButton.isEnabled = hasSlides
        stopButton.isEnabled = isPlaying
        previousButton.isEnabled = isPlaying
        nextButton.isEnabled = isPlaying
    }
}

// MARK: - UITableViewDelegate & DataSource
extension SlideshowViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPlaylist?.slides.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SlideCell", for: indexPath) as! SlideTableViewCell
        
        if let slide = currentPlaylist?.slides[indexPath.row] {
            cell.configure(with: slide)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard var playlist = currentPlaylist else { return }
            let slide = playlist.slides[indexPath.row]
            
            // Delete the media file
            SlideshowManager.shared.deleteMediaFile(fileName: slide.fileName)
            
            // Remove from playlist
            playlist.slides.remove(at: indexPath.row)
            SlideshowManager.shared.updatePlaylist(playlist)
            currentPlaylist = playlist
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateControlsState()
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard var playlist = currentPlaylist else { return }
        let slide = playlist.slides.remove(at: sourceIndexPath.row)
        playlist.slides.insert(slide, at: destinationIndexPath.row)
        
        // Update order
        for (index, var slide) in playlist.slides.enumerated() {
            var updatedSlide = slide
            // Note: SlideItem is a struct, we need to recreate it
            playlist.slides[index] = SlideItem(
                id: slide.id,
                fileName: slide.fileName,
                type: slide.type,
                duration: slide.duration,
                order: index
            )
        }
        
        SlideshowManager.shared.updatePlaylist(playlist)
        currentPlaylist = playlist
    }
}

// MARK: - PHPickerViewControllerDelegate
extension SlideshowViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty, var playlist = currentPlaylist else { return }
        
        for result in results {
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                // Handle image
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                    guard let self = self, let data = data else { return }
                    
                    let fileName = "\(UUID().uuidString).jpg"
                    if SlideshowManager.shared.saveMediaFile(data: data, fileName: fileName) != nil {
                        let slide = SlideItem(
                            fileName: fileName,
                            type: .image,
                            duration: playlist.settings.defaultImageDuration,
                            order: playlist.slides.count
                        )
                        
                        DispatchQueue.main.async {
                            playlist.slides.append(slide)
                            SlideshowManager.shared.updatePlaylist(playlist)
                            self.currentPlaylist = playlist
                            self.tableView.reloadData()
                            self.updateControlsState()
                        }
                    }
                }
            } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                // Handle video
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    guard let self = self, let url = url, let data = try? Data(contentsOf: url) else { return }
                    
                    let fileName = "\(UUID().uuidString).mp4"
                    if SlideshowManager.shared.saveMediaFile(data: data, fileName: fileName) != nil {
                        // Get video duration
                        let asset = AVAsset(url: url)
                        let duration = CMTimeGetSeconds(asset.duration)
                        
                        let slide = SlideItem(
                            fileName: fileName,
                            type: .video,
                            duration: duration,
                            order: playlist.slides.count
                        )
                        
                        DispatchQueue.main.async {
                            playlist.slides.append(slide)
                            SlideshowManager.shared.updatePlaylist(playlist)
                            self.currentPlaylist = playlist
                            self.tableView.reloadData()
                            self.updateControlsState()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SlideTableViewCell
class SlideTableViewCell: UITableViewCell {
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let durationLabel = UILabel()
    private let typeIcon = UIImageView()
    
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
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        durationLabel.font = .systemFont(ofSize: 14)
        durationLabel.textColor = .secondaryLabel
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationLabel)
        
        typeIcon.contentMode = .scaleAspectFit
        typeIcon.tintColor = .systemBlue
        typeIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(typeIcon)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),
            
            typeIcon.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            typeIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            typeIcon.widthAnchor.constraint(equalToConstant: 24),
            typeIcon.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            durationLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 8),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with slide: SlideItem) {
        titleLabel.text = slide.fileName
        durationLabel.text = String(format: "%.1fs", slide.duration)
        
        typeIcon.image = slide.type == .image ?
            UIImage(systemName: "photo.fill") :
            UIImage(systemName: "video.fill")
        
        // Load thumbnail
        let fileURL = SlideshowManager.shared.getMediaURL(for: slide.fileName)
        
        if slide.type == .image {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                thumbnailImageView.image = image
            }
        } else {
            // Generate video thumbnail
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
