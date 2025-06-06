
import UIKit
import AVFoundation

class LyricsDetailViewController: UIViewController {

    private let entry: LyricEntry
    private let textView = UITextView()
    private var audioPlayer: AVAudioPlayer?

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
        setupTextView()
        setupNavigationButton()
        renderLyrics()
    }

    private func setupTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Find Song",
            style: .plain,
            target: self,
            action: #selector(findMatchingSong)
        )
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

    @objc private func findMatchingSong() {
        let normalizedTitle = normalize(entry.title)
        let tracks = SharedLibraryManager.shared.libraryTracks

        var bestMatch: (name: String, distance: Int)? = nil

        for track in tracks {
            let distance = levenshtein(normalizedTitle, normalize(track))
            if bestMatch == nil || distance < bestMatch!.distance {
                bestMatch = (track, distance)
            }
        }

        guard let match = bestMatch else {
            showNoMatchAlert()
            return
        }

        if match.distance <= 3 {
            playTrack(named: match.name)
        } else {
            let alert = UIAlertController(
                title: "Closest Match Found",
                message: "Play “\(match.name)” for this reading?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Play", style: .default) { _ in
                self.playTrack(named: match.name)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }

    private func playTrack(named name: String) {
        guard let url = SharedLibraryManager.shared.urlForTrack(named: name) else {
            showNoMatchAlert()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            let alert = UIAlertController(title: "Playback Error", message: "Could not play “\(name)”", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    private func showNoMatchAlert() {
        let alert = UIAlertController(title: "No Match", message: "No matching song found for this reading.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func normalize(_ string: String) -> String {
        return string
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func levenshtein(_ aStr: String, _ bStr: String) -> Int {
        let a = Array(aStr)
        let b = Array(bStr)
        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)

        for i in 0...a.count { dist[i][0] = i }
        for j in 0...b.count { dist[0][j] = j }

        for i in 1...a.count {
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    dist[i][j] = dist[i - 1][j - 1]
                } else {
                    dist[i][j] = min(
                        dist[i - 1][j] + 1,
                        dist[i][j - 1] + 1,
                        dist[i - 1][j - 1] + 1
                    )
                }
            }
        }
        return dist[a.count][b.count]
    }
}
