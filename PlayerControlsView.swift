import UIKit

class PlayerControlsView: UIView {

    static var shared: PlayerControlsView?

    private let nowPlayingLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.text = ""
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }()

    private let cuedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = ""
        label.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return label
    }()

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

        // Progress
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0.001
        progressSlider.isContinuous = true
        progressSlider.addTarget(self, action: #selector(handleScrub), for: .valueChanged)
        progressSlider.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // Time
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textAlignment = .center
        timeLabel.text = "00:00 / 00:00"

        // Buttons
        fadeButton.onTap = { [weak self] in self?.onFadeOut?() }
        playPauseButton.onTap = { [weak self] in self?.onPlayPause?() }
        playCuedButton.onTap = { [weak self] in self?.onPlayCued?() }

        let buttonRow = UIStackView(arrangedSubviews: [fadeButton, playPauseButton, playCuedButton])
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

        // Volume
        let speakerIcon = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))
        speakerIcon.tintColor = UIColor.label
        speakerIcon.setContentHuggingPriority(.required, for: .horizontal)

        volumeSlider.value = AudioPlayerManager.shared.volume
        volumeSlider.addTarget(self, action: #selector(handleVolume), for: .valueChanged)

        let volumeRow = UIStackView(arrangedSubviews: [speakerIcon, volumeSlider])
        volumeRow.axis = .horizontal
        volumeRow.spacing = 8
        volumeRow.alignment = .center
        volumeRow.translatesAutoresizingMaskIntoConstraints = false

        // Stack
        let stack = UIStackView(arrangedSubviews: [
            nowPlayingLabel,
            cuedLabel,
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
            transportContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            transportContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Interactions

    @objc private func handleScrub() {
        onScrubProgress?(progressSlider.value)
    }

    @objc private func handleVolume() {
        onVolumeChange?(volumeSlider.value)
    }

    // MARK: - Public API

    func updatePlayingTrackText(_ title: String) {
//        nowPlayingLabel.text = "Now Playing: \(title)"
        nowPlayingLabel.text = (title)

    }

    func updateCuedTrackText(_ title: String) {
        cuedLabel.text = "🎧 Cued: \(title)"
    }

    func clearTrackText() {
        nowPlayingLabel.text = "Now Playing: —"
        cuedLabel.text = ""
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

//    func setFadeButtonTitle(_ title: String) {
//        print("🧪 Fade Button Title →", title)  // ✅ Debug log
//        
//        fadeButton.update(icon: fadeButton.currentIconName, title: title)
//    }

    func setFadeButtonTitle(_ title: String) {
        print("🧪 Fade Button Title →", title)

        fadeButton.update(icon: fadeButton.currentIconName, title: title)
//        fadeButton.setTitleColor(.white)
//        fadeButton.setBackgroundColor(.red)
    }

    
    func setVolumeSlider(value: Float) {
        volumeSlider.value = value
    }

    func updateFadeIcon(isFadingOut: Bool) {
        let icon = isFadingOut ? "radiowaves.right" : "radiowaves.left"
        fadeButton.update(icon: icon, title: fadeButton.currentTitle ?? "")
    }
    
    func clearCuedText() {
        cuedLabel.text = ""
    }

}
