import UIKit

class PlayerControlsView: UIView {

    let nowPlayingLabel = UILabel()
    let playPauseButton = UIButton(type: .system)
    let nextButton = UIButton(type: .system)
    let prevButton = UIButton(type: .system)
    let volumeSlider = UISlider()
    let progressSlider = UISlider()
    let timeLabel = UILabel()
    let fadeButton = UIButton(type: .system)
    let playlistButton = UIButton(type: .system)

    // MARK: - Callback closures
    var onPlayPauseTapped: (() -> Void)?
    var onNextTapped: (() -> Void)?
    var onPrevTapped: (() -> Void)?
    var onVolumeChanged: ((Float) -> Void)?
    var onScrub: ((Float) -> Void)?
    var onFadeTapped: (() -> Void)?
    var onPlaylistTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        nowPlayingLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nowPlayingLabel.textAlignment = .center
        nowPlayingLabel.text = "Now Playing: —"

        [playPauseButton, prevButton, nextButton].forEach {
            $0.tintColor = .black
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 64).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 64).isActive = true
        }

        playPauseButton.setImage(UIImage(named: "button_play"), for: .normal)
        prevButton.setImage(UIImage(named: "button_prev"), for: .normal)
        nextButton.setImage(UIImage(named: "button_next"), for: .normal)

        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
        volumeSlider.value = 0.5

        progressSlider.addTarget(self, action: #selector(scrubbed(_:)), for: .valueChanged)

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.textAlignment = .center
        timeLabel.text = "0:00 / 0:00"

        fadeButton.setTitle("Fade Out", for: .normal)
        fadeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        fadeButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        fadeButton.layer.cornerRadius = 8
        fadeButton.setTitleColor(.black, for: .normal)
        fadeButton.addTarget(self, action: #selector(fadeTapped), for: .touchUpInside)

        playlistButton.setTitle("Play Playlist", for: .normal)
        playlistButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        playlistButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        playlistButton.layer.cornerRadius = 8
        playlistButton.setTitleColor(.black, for: .normal)
        playlistButton.addTarget(self, action: #selector(playlistTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [prevButton, playPauseButton, nextButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .equalSpacing

        let stack = UIStackView(arrangedSubviews: [
            nowPlayingLabel,
            progressSlider,
            timeLabel,
            buttonStack,
            volumeSlider,
            fadeButton,
            playlistButton
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func playPauseTapped() { onPlayPauseTapped?() }
    @objc private func nextTapped() { onNextTapped?() }
    @objc private func prevTapped() { onPrevTapped?() }
    @objc private func volumeChanged(_ sender: UISlider) { onVolumeChanged?(sender.value) }
    @objc private func scrubbed(_ sender: UISlider) { onScrub?(sender.value) }
    @objc private func fadeTapped() { onFadeTapped?() }
    @objc private func playlistTapped() { onPlaylistTapped?() }
}
