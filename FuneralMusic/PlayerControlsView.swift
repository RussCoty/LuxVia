import UIKit

class PlayerControlsView: UIView {

    static var shared: PlayerControlsView?

    private let titleLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let playCuedButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()
    private let volumeSlider = UISlider()
    private let fadeButton = UIButton(type: .system)

    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onScrubProgress: ((Float) -> Void)?
    var onVolumeChange: ((Float) -> Void)?
    var onFadeOut: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .secondarySystemBackground

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        configureIconButton(playPauseButton, icon: "play.fill", title: "Play")
        playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)

        configureIconButton(playCuedButton, icon: "forward.fill", title: "Play Cued")
        playCuedButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)

        configureIconButton(fadeButton, icon: "radiowaves.left", title: "Fade")
        fadeButton.addTarget(self, action: #selector(handleFade), for: .touchUpInside)

        progressSlider.addTarget(self, action: #selector(handleScrub), for: .valueChanged)

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textAlignment = .center

        volumeSlider.addTarget(self, action: #selector(handleVolume), for: .valueChanged)
        volumeSlider.value = AudioPlayerManager.shared.volume

        let buttonRow = UIStackView(arrangedSubviews: [
            playPauseButton,
            playCuedButton,
            fadeButton
        ])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 24
        buttonRow.distribution = .equalSpacing
        buttonRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            buttonRow,
            progressSlider,
            timeLabel,
            volumeSlider
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    private func configureIconButton(_ button: UIButton, icon: String, title: String) {
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.setTitle(title, for: .normal)
        button.tintColor = .label
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 36, left: -28, bottom: 0, right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: -10, left: 10, bottom: 10, right: 0)
    }


    // MARK: - Action Handlers

    @objc private func handlePlayPause() {
        onPlayPause?()
    }

    @objc private func handleNext() {
        onNext?()
    }

    @objc private func handleScrub() {
        onScrubProgress?(progressSlider.value)
    }

    @objc private func handleVolume() {
        onVolumeChange?(volumeSlider.value)
    }

    @objc private func handleFade() {
        onFadeOut?()
    }

    // MARK: - Public Methods

    func nowPlayingText(_ text: String) {
        titleLabel.text = text
    }

    func updatePlayButton(isPlaying: Bool) {
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: iconName)
        playPauseButton.setImage(image, for: .normal)
    }

    func updateProgress(current: Float) {
        progressSlider.value = current
    }

    func setMaxProgress(_ max: Float) {
        progressSlider.maximumValue = max
    }

    func updateTimeLabel(current: Int, duration: Int) {
        timeLabel.text = String(format: "%02d:%02d / %02d:%02d",
                                current / 60, current % 60,
                                duration / 60, duration % 60)
    }

    func setFadeButtonTitle(_ title: String) {
        fadeButton.setTitle(title, for: .normal)
    }

    func setVolumeSlider(value: Float) {
        volumeSlider.value = value
    }
}
