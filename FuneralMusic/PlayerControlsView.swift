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
        titleLabel.text = " " // avoid zero-height label
        titleLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true

        configureIconButton(fadeButton, icon: "radiowaves.right", title: "Fade", horizontalOffset: 10)
        fadeButton.addTarget(self, action: #selector(handleFade), for: .touchUpInside)

        configureIconButton(playPauseButton, icon: "play.fill", title: "Play")
        playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)

        configureIconButton(playCuedButton, icon: "forward.fill", title: "Play Cued", horizontalOffset: -10)
        playCuedButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)


        progressSlider.addTarget(self, action: #selector(handleScrub), for: .valueChanged)
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1 // Prevent zero-width slider
        progressSlider.value = 0.001     // Tiny visible indicator
        progressSlider.isContinuous = true
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.heightAnchor.constraint(equalToConstant: 20).isActive = true

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textAlignment = .center

        volumeSlider.addTarget(self, action: #selector(handleVolume), for: .valueChanged)
        volumeSlider.value = AudioPlayerManager.shared.volume

        let buttonRow = UIStackView(arrangedSubviews: [
            fadeButton,
            playPauseButton,
            playCuedButton
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

    private func configureIconButton(
        _ button: UIButton,
        icon: String,
        title: String,
        horizontalOffset: CGFloat = 0
    ) {
        guard let iconImage = UIImage(systemName: icon) else { return }

        let isWideIcon = icon.contains("radiowaves")

        button.setImage(iconImage, for: .normal)
        button.setTitle(title, for: .normal)
        button.tintColor = .label
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center

        let iconWidth = iconImage.size.width
        let extraLeft = isWideIcon ? 20.0 : 10.0

        button.titleEdgeInsets = UIEdgeInsets(
            top: 36,
            left: -iconWidth + horizontalOffset,
            bottom: 0,
            right: 0
        )
        button.imageEdgeInsets = UIEdgeInsets(
            top: -10,
            left: extraLeft + horizontalOffset,
            bottom: 10,
            right: 0
        )

        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 64).isActive = true
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
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
    func updateFadeIcon(isFadingOut: Bool) {
        let iconName = isFadingOut ? "radiowaves.right" : "radiowaves.left"
        let image = UIImage(systemName: iconName)
        fadeButton.setImage(image, for: .normal)
    }

}
