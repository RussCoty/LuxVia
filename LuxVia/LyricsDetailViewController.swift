import UIKit

class LyricsDetailViewController: UIViewController {

    private let entry: Lyric
    private let textView = UITextView()
    private let playButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let bottomBanner = UIView()
    //private var isPlaying = false

    init(entry: Lyric) {
        self.entry = entry
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = entry.title
        view.backgroundColor = .systemBackground
        setupLayout()
        renderLyrics()
    }

    private func setupLayout() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.textAlignment = .center
        textView.font = .systemFont(ofSize: 18)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.addSubview(textView)

        bottomBanner.translatesAutoresizingMaskIntoConstraints = false
        bottomBanner.backgroundColor = UIColor.secondarySystemBackground
        view.addSubview(bottomBanner)

        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .label
        playButton.addTarget(self, action: #selector(playMatchingSong), for: .touchUpInside)

        let hasAudio = entry.audioFileName != nil
        playButton.isEnabled = hasAudio
        playButton.alpha = hasAudio ? 1.0 : 0.5

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add to Service", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        addButton.addTarget(self, action: #selector(addToService), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [playButton, addButton])
        stack.axis = .horizontal
        stack.spacing = 24
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.translatesAutoresizingMaskIntoConstraints = false
        bottomBanner.addSubview(stack)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomBanner.topAnchor),

            bottomBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBanner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBanner.heightAnchor.constraint(equalToConstant: 60),

            stack.centerXAnchor.constraint(equalTo: bottomBanner.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: bottomBanner.centerYAnchor)
        ])
    }

    private func renderLyrics() {
        textView.attributedText = LyricsDetailViewController.attributedText(for: entry.body)
    }

    /// Utility for rendering lyrics/readings/booklet text with preserved newlines and clean formatting
    static func attributedText(for text: String) -> NSAttributedString {
        // Try to parse as HTML first
        if let data = text.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.paragraphSpacing = 8
                paragraphStyle.lineBreakMode = .byWordWrapping
                attributed.addAttributes([
                    .font: UIFont.systemFont(ofSize: 18),
                    .paragraphStyle: paragraphStyle
                ], range: NSRange(location: 0, length: attributed.length))
                return attributed
            }
        }
        // Fallback: plain text with preserved newlines
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.lineBreakMode = .byWordWrapping
        return NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 18),
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    @objc private func playMatchingSong() {
        guard let filename = entry.audioFileName else {
            print("[DEBUG] No audioFileName in entry: \(entry.title)")
            return
        }

        let trimmed = filename.replacingOccurrences(of: ".mp3", with: "")

        guard let url = SharedLibraryManager.shared.urlForTrack(named: trimmed) else {
            showAlert("Not Found", "Could not find audio file.")
            return
        }

        AudioPlayerManager.shared.play(url: url)

        // Switch to Music tab
        tabBarController?.selectedIndex = 0

        // Delay scroll until transition completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let nav = self.tabBarController?.viewControllers?.first as? UINavigationController,
               let musicVC = nav.topViewController as? MusicViewController {
                musicVC.scrollToTrack(named: trimmed)
            }
        }
    }



//    private func animateButtonIcon(to iconName: String) {
//        UIView.transition(with: playButton, duration: 0.25, options: .transitionCrossDissolve) {
//            self.playButton.setImage(UIImage(systemName: iconName), for: .normal)
//        }
//    }

    @objc private func addToService() {
        if let filename = entry.audioFileName {
            let trimmed = filename.replacingOccurrences(of: ".mp3", with: "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let song = SharedLibraryManager.shared.songForTrack(named: trimmed) {
                let songFile = song.fileName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let songTitle = song.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                // Search allLyrics for a matching lyric with non-empty body
                let allLyricsSources = SharedLibraryManager.shared.allLyrics
                let lyric = allLyricsSources.first {
                    let lyricAudio = $0.audioFileName?.replacingOccurrences(of: ".mp3", with: "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let lyricTitle = $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let audioMatch = lyricAudio == songFile || lyricAudio == trimmed
                    let titleMatch = lyricTitle == songTitle || lyricTitle == entry.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return (audioMatch || titleMatch) && !$0.body.isEmpty
                }
                if let lyric = lyric {
                    print("[DEBUG] Lyric matched robustly: title=[\(lyric.title)], audioFileName=[\(lyric.audioFileName ?? \"nil\")], uid=[\(lyric.uid ?? -1)], body.isEmpty=[\(lyric.body.isEmpty)]")
                } else {
                    print("[DEBUG] No lyric match found for song: title=[\(song.title)], fileName=[\(song.fileName)]")
                }
                let serviceItem: ServiceItem
                if let lyric = lyric {
                    serviceItem = ServiceItem(
                        type: .song,
                        title: song.title,
                        subtitle: nil,
                        fileName: song.fileName,
                        customText: lyric.body, // Set lyrics text if available
                        uid: lyric.uid // Set uid from matched lyric
                    )
                } else {
                    serviceItem = ServiceItem(
                        type: .song,
                        title: song.title,
                        subtitle: nil,
                        fileName: song.fileName,
                        customText: nil,
                        uid: nil
                    )
                }

                if ServiceOrderManager.shared.items.contains(where: { $0.fileName == song.fileName && $0.type == .music }) {
                    showToast("Already in Order: \(song.title)")
                    return
                }

                ServiceOrderManager.shared.add(serviceItem)
                showToast("Added: \(song.title)")
            } else {
                showToast("MP3 not found for: \(entry.title)")
            }
        } else {
            let reading = ServiceItem(
                type: .reading,
                title: entry.title,
                subtitle: nil,
                customText: entry.body
            )

            if ServiceOrderManager.shared.items.contains(where: { $0.title == entry.title && $0.type == .reading }) {
                showToast("Already in Order: \(reading.title)")
                return
            }

            ServiceOrderManager.shared.add(reading)
            showToast("Added: \(reading.title)")
        }
    }



    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.backgroundColor = UIColor.systemGreen
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 6
        toastLabel.clipsToBounds = true
        toastLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let padding: CGFloat = 12
        toastLabel.frame = CGRect(
            x: padding,
            y: view.safeAreaInsets.top + 16,
            width: view.frame.width - padding * 2,
            height: 36
        )
        view.addSubview(toastLabel)

        UIView.animate(withDuration: 0.25, animations: {
            toastLabel.alpha = 1.0
            toastLabel.transform = .identity
        }) { _ in
            UIView.animate(
                withDuration: 0.25,
                delay: 2.0,
                options: .curveEaseInOut,
                animations: {
                    toastLabel.alpha = 0.0
                    toastLabel.transform = CGAffineTransform(translationX: 0, y: -10)
                }, completion: { _ in
                    toastLabel.removeFromSuperview()
                }
            )
        }
    }
}
