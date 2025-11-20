import UIKit
import SwiftUI
import AVFoundation
//import MarkdownUI
// 

class CustomReadingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var customReadings: [CustomReading] = []
    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
        private let aiEulogyButton = UIButton(type: .system)
        private let recordButton = UIButton(type: .system)
        private let imageManagerButton = UIButton(type: .system)
    
    // Slideshow preview components
    private let slideshowPreviewContainer = UIView()
    private let slideshowPreviewImageView = UIImageView()
    private let slideshowPreviewLabel = UILabel()
    private let slideshowStatusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        customReadings = CustomReadingStore.shared.load()
        
        setupSlideshowPreview()
        setupAddButton()
            setupAIEulogyButton()
            setupRecordButton()
            setupImageManagerButton()
        setupTableView()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSlideshowPreview()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupSlideshowPreview() {
        // Container
        slideshowPreviewContainer.backgroundColor = .secondarySystemBackground
        slideshowPreviewContainer.layer.cornerRadius = 12
        slideshowPreviewContainer.layer.borderWidth = 2
        slideshowPreviewContainer.layer.borderColor = UIColor.systemGray4.cgColor
        slideshowPreviewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slideshowPreviewContainer)
        
        // Preview image
        slideshowPreviewImageView.contentMode = .scaleAspectFit
        slideshowPreviewImageView.backgroundColor = .black
        slideshowPreviewImageView.layer.cornerRadius = 8
        slideshowPreviewImageView.clipsToBounds = true
        slideshowPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        slideshowPreviewContainer.addSubview(slideshowPreviewImageView)
        
        // Preview label
        slideshowPreviewLabel.text = "Slideshow Monitor"
        slideshowPreviewLabel.textAlignment = .center
        slideshowPreviewLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        slideshowPreviewLabel.textColor = .label
        slideshowPreviewLabel.translatesAutoresizingMaskIntoConstraints = false
        slideshowPreviewContainer.addSubview(slideshowPreviewLabel)
        
        // Status label
        slideshowStatusLabel.text = "No slideshow playing"
        slideshowStatusLabel.textAlignment = .center
        slideshowStatusLabel.font = .systemFont(ofSize: 10, weight: .regular)
        slideshowStatusLabel.textColor = .secondaryLabel
        slideshowStatusLabel.numberOfLines = 2
        slideshowStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        slideshowPreviewContainer.addSubview(slideshowStatusLabel)
        
        NSLayoutConstraint.activate([
            slideshowPreviewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            slideshowPreviewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            slideshowPreviewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            slideshowPreviewContainer.heightAnchor.constraint(equalToConstant: 140),
            
            slideshowPreviewImageView.topAnchor.constraint(equalTo: slideshowPreviewContainer.topAnchor, constant: 8),
            slideshowPreviewImageView.centerXAnchor.constraint(equalTo: slideshowPreviewContainer.centerXAnchor),
            slideshowPreviewImageView.widthAnchor.constraint(equalToConstant: 160),
            slideshowPreviewImageView.heightAnchor.constraint(equalToConstant: 90),
            
            slideshowPreviewLabel.topAnchor.constraint(equalTo: slideshowPreviewImageView.bottomAnchor, constant: 4),
            slideshowPreviewLabel.leadingAnchor.constraint(equalTo: slideshowPreviewContainer.leadingAnchor, constant: 8),
            slideshowPreviewLabel.trailingAnchor.constraint(equalTo: slideshowPreviewContainer.trailingAnchor, constant: -8),
            
            slideshowStatusLabel.topAnchor.constraint(equalTo: slideshowPreviewLabel.bottomAnchor, constant: 2),
            slideshowStatusLabel.leadingAnchor.constraint(equalTo: slideshowPreviewContainer.leadingAnchor, constant: 8),
            slideshowStatusLabel.trailingAnchor.constraint(equalTo: slideshowPreviewContainer.trailingAnchor, constant: -8),
            slideshowStatusLabel.bottomAnchor.constraint(lessThanOrEqualTo: slideshowPreviewContainer.bottomAnchor, constant: -8)
        ])
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
        
        // Listen for external display connection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalDisplayChanged),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalDisplayChanged),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }
    
    private func setupAddButton() {
        addButton.setTitle("➕ Add Custom Reading", for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        addButton.addTarget(self, action: #selector(addReading), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: slideshowPreviewContainer.bottomAnchor, constant: 12),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

        private func setupAIEulogyButton() {
            aiEulogyButton.setTitle("🧠 Write Eulogy with AI", for: .normal)
            aiEulogyButton.setTitleColor(.systemPurple, for: .normal)
            aiEulogyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            aiEulogyButton.addTarget(self, action: #selector(openAIEulogyWriter), for: .touchUpInside)
            aiEulogyButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(aiEulogyButton)
            NSLayoutConstraint.activate([
                aiEulogyButton.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 12),
                aiEulogyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    
        private func setupRecordButton() {
            recordButton.setTitle("🎤 Record Custom Reading", for: .normal)
            recordButton.setTitleColor(.systemBlue, for: .normal)
            recordButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            recordButton.addTarget(self, action: #selector(recordCustomReading), for: .touchUpInside)
            recordButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(recordButton)
            NSLayoutConstraint.activate([
                recordButton.topAnchor.constraint(equalTo: aiEulogyButton.bottomAnchor, constant: 12),
                recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    
        private func setupImageManagerButton() {
            imageManagerButton.setTitle("🖼️ Manage Slideshow Images", for: .normal)
            imageManagerButton.setTitleColor(.systemOrange, for: .normal)
            imageManagerButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            imageManagerButton.addTarget(self, action: #selector(openImageManager), for: .touchUpInside)
            imageManagerButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageManagerButton)
            NSLayoutConstraint.activate([
                imageManagerButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 12),
                imageManagerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    
    @objc private func openAIEulogyWriter() {
        let vc = UIHostingController(rootView: EulogyWriterView.make())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func openImageManager() {
        let imageManagerVC = ImageManagerViewController()
        navigationController?.pushViewController(imageManagerVC, animated: true)
    }
    
    // MARK: - Slideshow Preview Methods
    
    @objc private func slideshowDidStart() {
        updateSlideshowPreview()
    }
    
    @objc private func slideshowDidUpdate(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let index = userInfo["index"] as? Int,
              let slide = userInfo["slide"] as? SlideItem else { return }
        
        if let playlist = SlideshowManager.shared.getCurrentPlaylist() {
            slideshowStatusLabel.text = "Playing: \(playlist.name)\nSlide \(index + 1) of \(playlist.slides.count)"
        }
        
        // Update preview image
        updatePreviewImage(with: slide)
    }
    
    @objc private func slideshowDidStop() {
        slideshowPreviewImageView.image = nil
        slideshowPreviewLabel.text = "Slideshow Monitor"
        slideshowStatusLabel.text = "No slideshow playing"
    }
    
    @objc private func externalDisplayChanged() {
        // Update status when AirPlay connects/disconnects
        updateSlideshowPreview()
        
        let externalScreens = UIScreen.screens.filter { $0 != UIScreen.main }
        if !externalScreens.isEmpty {
            print("📺 External display detected in Words tab")
            slideshowPreviewContainer.layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            print("📺 No external display in Words tab")
            slideshowPreviewContainer.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
    
    private func updateSlideshowPreview() {
        let externalScreenConnected = UIScreen.screens.count > 1
        
        if SlideshowManager.shared.isCurrentlyPlaying() {
            if let slide = SlideshowManager.shared.getCurrentSlide() {
                updatePreviewImage(with: slide)
                
                if let playlist = SlideshowManager.shared.getCurrentPlaylist() {
                    let index = SlideshowManager.shared.getCurrentSlideIndex()
                    let airplayStatus = externalScreenConnected ? "📺 On AirPlay" : "⚠️ No Video"
                    slideshowStatusLabel.text = "\(airplayStatus)\n\(playlist.name)\nSlide \(index + 1)/\(playlist.slides.count)"
                }
            }
            slideshowPreviewContainer.layer.borderColor = externalScreenConnected ? UIColor.systemGreen.cgColor : UIColor.systemOrange.cgColor
        } else {
            slideshowPreviewImageView.image = nil
            slideshowPreviewLabel.text = "Slideshow Monitor"
            if externalScreenConnected {
                slideshowStatusLabel.text = "Ready ✓\nAirPlay video connected"
            } else {
                slideshowStatusLabel.text = "Not playing\nEnable screen mirroring\non AirPlay device"
            }
            slideshowPreviewContainer.layer.borderColor = externalScreenConnected ? UIColor.systemGreen.cgColor : UIColor.systemGray4.cgColor
        }
    }
    
    private func updatePreviewImage(with slide: SlideItem) {
        let fileURL = SlideshowManager.shared.getMediaURL(for: slide.fileName)
        
        if slide.type == .image {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                slideshowPreviewImageView.image = image
                slideshowPreviewLabel.text = "Now Playing"
            }
        } else {
            // Generate video thumbnail
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVAsset(url: fileURL)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                let time = CMTime(seconds: 1, preferredTimescale: 60)
                if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                    DispatchQueue.main.async {
                        self.slideshowPreviewImageView.image = UIImage(cgImage: cgImage)
                        self.slideshowPreviewLabel.text = "Now Playing (Video)"
                    }
                }
            }
        }
    }
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: imageManagerButton.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
        @objc private func recordCustomReading() {
            let recorderVC = UIHostingController(rootView: WordRecorderView())
            navigationController?.pushViewController(recorderVC, animated: true)
        }
    @objc private func addReading() {
        let editorVC = CustomReadingEditorViewController()
        
        editorVC.onSave = { [weak self] newReading in
            // Save only on manual Save
            CustomReadingStore.shared.add(newReading)
            self?.customReadings = CustomReadingStore.shared.load()
            self?.tableView.reloadData()
        }
        
        editorVC.onAddToService = { [weak self] reading in
            // ❌ DO NOT save again here!
            self?.customReadings = CustomReadingStore.shared.load()
            self?.tableView.reloadData()
            
            let serviceItem = ServiceItem(
                type: .customReading,
                title: reading.title,
                subtitle: nil,
                customText: reading.content
            )
            
            ServiceOrderManager.shared.add(serviceItem)
            self?.tabBarController?.selectedIndex = 0
        }
        
        navigationController?.pushViewController(editorVC, animated: true)
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        customReadings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reading = customReadings[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = reading.title
        
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add to Service", for: .normal)
        addButton.tag = indexPath.row
        addButton.addTarget(self, action: #selector(addToService(_:)), for: .touchUpInside)
        cell.accessoryView = addButton
        
        return cell
    }
    
    // MARK: - Add to Service
    
    @objc private func addToService(_ sender: UIButton) {
        let reading = customReadings[sender.tag]
        let serviceItem = ServiceItem(
            type: .customReading,
            title: reading.title,
            subtitle: nil,
            customText: reading.content
        )
        print("Adding to service:", serviceItem)
        ServiceOrderManager.shared.add(serviceItem)
    }
    
    // MARK: - UITableView Editing
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let reading = customReadings[indexPath.row]
            CustomReadingStore.shared.remove(id: reading.id)
            customReadings.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: - UITableView Selection
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reading = customReadings[indexPath.row]
        let editorVC = CustomReadingEditorViewController()
        editorVC.setReading(reading)
        editorVC.onSave = { [weak self] updated in
            CustomReadingStore.shared.update(updated.id, with: updated)
            self?.customReadings = CustomReadingStore.shared.load()
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(editorVC, animated: true)
    }
    
    
}
