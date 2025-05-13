import UIKit

class PlayerControlsView: UIView {
    // MARK: - Shared Instance
    static var shared: PlayerControlsView?

    // MARK: - Callbacks
    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onVolumeChange: ((Float) -> Void)?
    var onScrubProgress: ((Float) -> Void)?
    var onFadeOut: (() -> Void)?
    var onPlayPlaylist: (() -> Void)?

    // MARK: - UI Elements
    private let nowPlayingLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let previousButton = UIButton(type: .system)
    private let fadeButton = UIButton(type: .system)
    private let playPlaylistButton = UIButton(type: .system)
    private let volumeSlider = UISlider()
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()

    // MARK: - Public property
    var currentVolume: Float {
        return volumeSlider.value
    }

    // MARK: - Init
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

    // MARK: - UI Setup
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

        configureImageButton(playPauseButton, imageName: "button_play")
        configureImageButton(nextButton, imageName: "button_next")
        configureImageButton(previousButton, imageName: "button_prev")

        fadeButton.setTitle("Fade", for: .normal)
        playPlaylistButton.setTitle("Play Playlist", for: .normal)

        [fadeButton, playPlaylistButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.tintColor = .black
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        }

        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        fadeButton.addTarget(self, action: #selector(fadeTapped), for: .touchUpInside)
        playPlaylistButton.addTarget(self, action: #selector(playPlaylistTapped), for: .touchUpInside)

        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.value = AudioPlayerManager.shared.volume
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)

        if let wedgeImage = generateWedgeImage() {
            volumeSlider.setMinimumTrackImage(wedgeImage, for: .normal)
        }

        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(progressChanged(_:)), for: .valueChanged)

        let transportStack = UIStackView(arrangedSubviews: [previousButton, playPauseButton, nextButton])
        transportStack.axis = .horizontal
        transportStack.distribution = .fillEqually
        transportStack.spacing = 12
        transportStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(nowPlayingLabel)
        addSubview(transportStack)
        addSubview(fadeButton)
        addSubview(playPlaylistButton)
        addSubview(volumeSlider)
        addSubview(progressSlider)
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            nowPlayingLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            nowPlayingLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nowPlayingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            transportStack.topAnchor.constraint(equalTo: nowPlayingLabel.bottomAnchor, constant: 8),
            transportStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            transportStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            transportStack.heightAnchor.constraint(equalToConstant: 60),

            fadeButton.topAnchor.constraint(equalTo: transportStack.bottomAnchor, constant: 8),
            fadeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            fadeButton.widthAnchor.constraint(equalToConstant: 80),
            fadeButton.heightAnchor.constraint(equalToConstant: 36),

            playPlaylistButton.topAnchor.constraint(equalTo: transportStack.bottomAnchor, constant: 8),
            playPlaylistButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            playPlaylistButton.widthAnchor.constraint(equalToConstant: 120),
            playPlaylistButton.heightAnchor.constraint(equalToConstant: 36),

            volumeSlider.topAnchor.constraint(equalTo: fadeButton.bottomAnchor, constant: 8),
            volumeSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            volumeSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            progressSlider.topAnchor.constraint(equalTo: volumeSlider.bottomAnchor, constant: 8),
            progressSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            timeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -6),
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
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

        let startHeight: CGFloat = 0
        let endHeight: CGFloat = height * 2

        context.beginPath()
        context.move(to: CGPoint(x: 0, y: height))
        context.addLine(to: CGPoint(x: 0, y: height - startHeight))
        context.addLine(to: CGPoint(x: width, y: height - endHeight))
        context.addLine(to: CGPoint(x: width, y: height))
        context.closePath()
        context.fillPath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }

    // MARK: - Button Actions
    @objc private func playPauseTapped() { onPlayPause?() }
    @objc private func nextTapped() { onNext?() }
    @objc private func previousTapped() { onPrevious?() }
    @objc private func fadeTapped() { onFadeOut?() }
    @objc private func playPlaylistTapped() { onPlayPlaylist?() }

    @objc private func volumeChanged(_ sender: UISlider) {
        AudioPlayerManager.shared.volume = sender.value
        onVolumeChange?(sender.value)
    }

    @objc private func progressChanged(_ sender: UISlider) {
        onScrubProgress?(sender.value)
    }

    // MARK: - Public Update Methods
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
}
