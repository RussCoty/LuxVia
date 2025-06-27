import UIKit

class PlayerControlsView: UIView {

    static var shared: PlayerControlsView?

    private let titleLabel = UILabel()
    private let cuedTrackLabel = UILabel()
    private let fadeButton = IconLabelButtonView(icon: "radiowaves.right", title: "Fade Out")
    private let playPauseButton = IconLabelButtonView(icon: "play.fill", title: "Play")
    private let playCuedButton = IconLabelButtonView(icon: "forward.fill", title: "Play Cued")

    private let progressSlider = UISlider()
    private let timeLabel = UILabel()
    private let volumeSlider = UISlider()

    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onScrubProgress: ((Float) -> Void)?
    var onVolumeChange: ((Float) -> Void)?
    var onFadeOut: (() -> Void)?
    var onPlayCued: (() -> Void)?

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
        // Title Track Label
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.text = " "
        titleLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        
        
        // Cued Track Label
        cuedTrackLabel.font = .systemFont(ofSize: 12)
        cuedTrackLabel.textColor = .secondaryLabel
        cuedTrackLabel.textAlignment = .center
        cuedTrackLabel.text = " " // Preserve height even when empty
        cuedTrackLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true

        // Fade Button
        fadeButton.onTap = { [weak self] in self?.onFadeOut?() }
        // Play-Pause
        playPauseButton.onTap = { [weak self] in self?.onPlayPause?() }
        playCuedButton.onTap = { [weak self] in self?.onPlayCued?() }

        progressSlider.addTarget(self, action: #selector(handleScrub), for: .valueChanged)
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0.001
        progressSlider.isContinuous = true
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.heightAnchor.constraint(equalToConstant: 20).isActive = true

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textAlignment = .center
        timeLabel.text = "00:00 / 00:00"


        volumeSlider.addTarget(self, action: #selector(handleVolume), for: .valueChanged)
        volumeSlider.value = AudioPlayerManager.shared.volume
        //let speakerIcon = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))


        let buttonRow = UIStackView(arrangedSubviews: [
            fadeButton, playPauseButton, playCuedButton
        ])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 24
        buttonRow.distribution = .equalSpacing
        buttonRow.alignment = .center
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let transportContainer = UIView()
        transportContainer.translatesAutoresizingMaskIntoConstraints = false
        transportContainer.addSubview(buttonRow)

        NSLayoutConstraint.activate([
            buttonRow.topAnchor.constraint(equalTo: transportContainer.topAnchor),
            buttonRow.bottomAnchor.constraint(equalTo: transportContainer.bottomAnchor),
            buttonRow.centerXAnchor.constraint(equalTo: transportContainer.centerXAnchor)
        ])
        
        let speakerIcon = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))
        speakerIcon.tintColor = UIColor.label
        speakerIcon.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)

        volumeSlider.addTarget(self, action: #selector(handleVolume), for: .valueChanged)
        volumeSlider.value = AudioPlayerManager.shared.volume

        let volumeRow = UIStackView(arrangedSubviews: [speakerIcon, volumeSlider])
        volumeRow.axis = NSLayoutConstraint.Axis.horizontal
        volumeRow.spacing = 8
        volumeRow.alignment = UIStackView.Alignment.center
        volumeRow.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            cuedTrackLabel,
            transportContainer,
            progressSlider,
            timeLabel,
            volumeRow
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            transportContainer.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.95),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }


    @objc private func handleScrub() {
        onScrubProgress?(progressSlider.value)
    }

    @objc private func handleVolume() {
        onVolumeChange?(volumeSlider.value)
    }

    // MARK: - Public Methods

    func nowPlayingText(_ text: String) {
        titleLabel.text = text
    }

    func updatePlayButton(isPlaying: Bool) {
        let icon = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.update(icon: icon, title: isPlaying ? "Pause" : "Play")
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
        fadeButton.update(icon: fadeButton.currentIconName, title: title)
    }

    func setVolumeSlider(value: Float) {
        volumeSlider.value = value
    }

    func updateFadeIcon(isFadingOut: Bool) {
        let icon = isFadingOut ? "radiowaves.right" : "radiowaves.left"
        fadeButton.update(icon: icon, title: fadeButton.currentTitle ?? "")
    }
    func updateCuedTrackText(_ title: String?) {
        if let title = title, !title.isEmpty {
            cuedTrackLabel.text = "🎧 Cued: \(title)"
        } else {
            cuedTrackLabel.text = " "
        }
    }

}
