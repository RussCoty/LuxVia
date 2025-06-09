
import UIKit

class LyricsDetailViewController: UIViewController {

    private let entry: LyricEntry
    private let textView = UITextView()
    private let playButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let bottomBanner = UIView()
    private var isPlaying = false

    init(entry: LyricEntry) {
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

        let hasAudio = entry.musicFilename != nil
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
        if let data = entry.body.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.paragraphSpacing = 8
                attributed.addAttributes([
                    .font: UIFont.systemFont(ofSize: 18),
                    .paragraphStyle: paragraphStyle
                ], range: NSRange(location: 0, length: attributed.length))
                textView.attributedText = attributed
            } else {
                textView.text = entry.body
            }
        } else {
            textView.text = entry.body
        }
    }

    @objc private func playMatchingSong() {
        guard let filename = entry.musicFilename else {
            print("[DEBUG] No musicFilename in entry: \(entry.title)")
            return
        }

        let trimmed = filename.replacingOccurrences(of: ".mp3", with: "")
        print("[DEBUG] Requested filename:", filename)
        print("[DEBUG] Trimmed base name:", trimmed)

        guard let url = SharedLibraryManager.shared.urlForTrack(named: trimmed) else {
            print("[DEBUG] MP3 not found in SharedLibraryManager. All available files:")
            SharedLibraryManager.shared.allSongs.forEach { print("- \($0.fileName)") }
            showAlert("Not Found", "Could not find audio file.")
            return
        }

        if isPlaying {
            AudioPlayerManager.shared.stop()
            animateButtonIcon(to: "play.fill")
        } else {
            AudioPlayerManager.shared.play(url: url)
            animateButtonIcon(to: "pause.fill")
        }

        isPlaying.toggle()
    }


    private func animateButtonIcon(to iconName: String) {
        UIView.transition(with: playButton, duration: 0.25, options: .transitionCrossDissolve) {
            self.playButton.setImage(UIImage(systemName: iconName), for: .normal)
        }
    }

    @objc private func addToService() {
        if let filename = entry.musicFilename {
            let trimmed = filename.replacingOccurrences(of: ".mp3", with: "")
            if let song = SharedLibraryManager.shared.songForTrack(named: trimmed) {

                if OrderOfServiceManager.shared.contains(.song(song)) {
                    showToast("Already in Order: \(song.title)")
                    return
                }

                OrderOfServiceManager.shared.addItem(.song(song))
                showToast("Added: \(song.title)")
            } else {
                showToast("MP3 not found for: \(entry.title)")
            }
        } else {
            let reading = ReadingEntry(title: entry.title, text: entry.body)

            if OrderOfServiceManager.shared.contains(.reading(reading)) {
                showToast("Already in Order: \(reading.title)")
                return
            }

            OrderOfServiceManager.shared.addItem(.reading(reading))
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
