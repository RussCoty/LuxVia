import UIKit

final class IconLabelButtonView: UIControl {

    private let iconView = UIImageView()
    private let label = UILabel()

    private var tapAction: (() -> Void)?

    init(icon: String, title: String, action: @escaping () -> Void) {
        super.init(frame: .zero)
        setup(icon: icon, title: title)
        tapAction = action
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup(icon: String, title: String) {
        iconView.image = UIImage(systemName: icon)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .label

        label.text = title
        label.font = .systemFont(ofSize: 12)
        label.textColor = .label
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func didTap() {
        tapAction?()
    }

    func update(icon: String, title: String) {
        iconView.image = UIImage(systemName: icon)
        label.text = title
    }
}
