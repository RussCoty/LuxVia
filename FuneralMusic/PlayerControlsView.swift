import UIKit

class PlayerControlsView: UIView {
    static var shared: PlayerControlsView?

    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onVolumeChange: ((Float) -> Void)?
    var onScrubProgress: ((Float) -> Void)?
    var onFadeOut: (() -> Void)?

    private let nowPlayingLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let previousButton = UIButton(type: .system)
    private let fadeButton = UIButton(type: .system)
    private let volumeSlider = UISlider()
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()
    private let volumeLabel = UILabel()

    var currentVolume: Float { volumeSlider.value }

    override init(frame: CGRect) {
        super.init(frame: frame)
        PlayerControlsView.shared = self
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        PlayerControlsView.shared = self
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor(white: 0.95, alpha: 1.0)

        nowPlayingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nowPlayingLabel.textAlignment = .center
        nowPlayingLabel.text = "Now Playing: —"
        nowPlayingLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.textAlignment = .center
        timeLabel.text = "0:00 / 0:00"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        volumeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        volumeLabel.textAlignment = .center
        volumeLabel.text = "Volume: 50%"
        volumeLabel.translatesAutoresizingMaskIntoConstraints = false

        configureImageButton(playPauseButton, imageName: "button_play")
        configureImageButton(nextButton, imageName: "button_next")
        configureImageButton(previousButton, imageName: "button_prev")

        [playPauseButton, previousButton, nextButton].forEach {
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }

        fadeButton.setTitle("Fade Out", for: .normal)
        fadeButton.tintColor = .black
        fadeButton.setTitleColor(.black, for: .normal)
        fadeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        fadeButton.backgroundColor = UIColor.systemGray5
        fadeButton.layer.cornerRadius = 8
        fadeButton.translatesAutoresizingMaskIntoConstraints = false
        fadeButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        fadeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        fadeButton.setContentHuggingPriority(.required, for: .horizontal)

        volumeSlider.value = AudioPlayerManager.shared.volume
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.setContentHuggingPriority(.defaultLow, for: .horizontal)
        volumeSlider.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        volumeSlider.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true

        if let wedgeImage = generateWedgeImage() {
            volumeSlider.setMinimumTrackImage(wedgeImage, for: .normal)
        }

        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(progressChanged(_:)), for: .valueChanged)

        let transportStack = UIStackView(arrangedSubviews: [previousButton, playPauseButton, nextButton])
        transportStack.axis = .horizontal
        transportStack.distribution = .fillEqually
        transportStack.spacing = 16
        transportStack.translatesAutoresizingMaskIntoConstraints = false

        let volumeStack = UIStackView(arrangedSubviews: [volumeSlider, volumeLabel])
        volumeStack.axis = .vertical
        volumeStack.alignment = .center
        volumeStack.spacing = 4
        volumeStack.translatesAutoresizingMaskIntoConstraints = false

        let fadeVolumeStack = UIStackView(arrangedSubviews: [fadeButton, volumeStack])
        fadeVolumeStack.axis = .horizontal
        fadeVolumeStack.alignment = .center
        fadeVolumeStack.spacing = 20
        fadeVolumeStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(nowPlayingLabel)
        addSubview(transportStack)
        addSubview(fadeVolumeStack)
        addSubview(progressSlider)
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            nowPlayingLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            nowPlayingLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nowPlayingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            transportStack.topAnchor.constraint(equalTo: nowPlayingLabel.bottomAnchor, constant: 8),
            transportStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            transportStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            transportStack.heightAnchor.constraint(equalToConstant: 50),

            fadeVolumeStack.topAnchor.constraint(equalTo: transportStack.bottomAnchor, constant: 12),
            fadeVolumeStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            fadeVolumeStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            progressSlider.topAnchor.constraint(equalTo: fadeVolumeStack.bottomAnchor, constant: 12),
            progressSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            timeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -6),
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        fadeButton.addTarget(self, action: #selector(fadeTapped), for: .touchUpInside)
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: imageName), for: .normal)
        button.tintColor = .black
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
    }

    private func generateWedgeImage(width: CGFloat = 300, height: CGFloat = 10, color: UIColor = .black) -> UIImage? {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(color.cgColor)

        // Steep wedge: starts at 0, ends much taller
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: height))
        context.addLine(to: CGPoint(x: 0, y: height - 0.2 * height))   // near bottom
        context.addLine(to: CGPoint(x: width, y: height - 1.2 * height)) // loud end = much higher
        context.addLine(to: CGPoint(x: width, y: height))
        context.closePath()
        context.fillPath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }


    @objc private func playPauseTapped() { onPlayPause?() }
    @objc private func nextTapped() { onNext?() }
    @objc private func previousTapped() { onPrevious?() }
    @objc private func fadeTapped() { onFadeOut?() }

    @objc private func volumeChanged(_ sender: UISlider) {
        let percent = Int(sender.value * 100)
        volumeLabel.text = "Volume: \(percent)%"
        AudioPlayerManager.shared.volume = sender.value
        onVolumeChange?(sender.value)
    }

    @objc private func progressChanged(_ sender: UISlider) {
        onScrubProgress?(sender.value)
    }

    func updatePlayButton(isPlaying: Bool) {
        let imageName = isPlaying ? "button_pause" : "button_play"
        playPauseButton.setImage(UIImage(named: imageName), for: .normal)
    }

    func nowPlayingText(_ text: String) {
        nowPlayingLabel.text = text
    }

    func updateProgress(current: Float) {
        progressSlider.value = current
    }

    func setMaxProgress(_ max: Float) {
        progressSlider.maximumValue = max
    }

    func updateTimeLabel(current: Int, duration: Int) {
        let currentMin = current / 60
        let currentSec = current % 60
        let durationMin = duration / 60
        let durationSec = duration % 60
        timeLabel.text = String(format: "%d:%02d / %d:%02d", currentMin, currentSec, durationMin, durationSec)
    }

    func setFadeButtonTitle(_ title: String) {
        fadeButton.setTitle(title, for: .normal)
    }
}
