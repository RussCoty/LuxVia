import UIKit

class IconLabelButtonView: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private var tapGesture: UITapGestureRecognizer?

    var currentIconName: String = ""
    var currentTitle: String? {
        return titleLabel.text
    }

    var onTap: (() -> Void)?

    init(icon: String, title: String) {
        super.init(frame: .zero)
        setup(icon: icon, title: title)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(icon: "questionmark", title: "Unknown")
    }

    private func setup(icon: String, title: String) {
        currentIconName = icon
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        titleLabel.text = title
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.widthAnchor.constraint(equalToConstant: 64)
        ])

        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        if let gesture = tapGesture {
            addGestureRecognizer(gesture)
        }

        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 64).isActive = true
        heightAnchor.constraint(equalToConstant: 64).isActive = true
    }

    func update(icon: String, title: String) {
        print("🎯 IconLabelButtonView.update called — title =", title)
        currentIconName = icon
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
    }

    @objc private func tapped() {
        onTap?()
    }
}
