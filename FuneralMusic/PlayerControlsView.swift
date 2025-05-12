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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        nowPlayingLabel.text = "Now Playing: —"
        nowPlayingLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nowPlayingLabel.textAlignment = .center

        playPauseButton.setImage(UIImage(named: "button_play"), for: .normal)
        prevButton.setImage(UIImage(named: "button_prev"), for: .normal)
        nextButton.setImage(UIImage(named: "button_next"), for: .normal)

        [playPauseButton, prevButton, nextButton].forEach {
            $0.tintColor = .black
            $0.imageView?.contentMode = .scaleAspectFit
            $0.heightAnchor.constraint(equalToConstant: 64).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 64).isActive = true
        }

        volumeSlider.tintColor = .gray
        progressSlider.tintColor = .gray

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.textAlignment = .center

        fadeButton.setTitle("Fade Out", for: .normal)
        fadeButton.setTitleColor(.black, for: .normal)
        fadeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        fadeButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        fadeButton.layer.cornerRadius = 8

        let buttonStack = UIStackView(arrangedSubviews: [prevButton, playPauseButton, nextButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .equalSpacing

        let controlsStack = UIStackView(arrangedSubviews: [
            nowPlayingLabel,
            progressSlider,
            timeLabel,
            buttonStack,
            volumeSlider,
            fadeButton
        ])
        controlsStack.axis = .vertical
        controlsStack.spacing = 10
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(controlsStack)

        NSLayoutConstraint.activate([
            controlsStack.topAnchor.constraint(equalTo: topAnchor),
            controlsStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            controlsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlsStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
