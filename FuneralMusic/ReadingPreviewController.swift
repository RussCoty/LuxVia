import UIKit

class ReadingPreviewViewController: UIViewController {

    private let readingTitle: String
    private let readingText: String

    init(title: String, text: String) {
        self.readingTitle = title
        self.readingText = text
        super.init(nibName: nil, bundle: nil)

        if #available(iOS 15.0, *) {
            modalPresentationStyle = .pageSheet
            if let sheet = sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
        } else {
            modalPresentationStyle = .formSheet
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.textAlignment = .center
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.backgroundColor = .clear

        if let data = readingText.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.paragraphSpacing = 8
                attributed.addAttributes([
                    .font: UIFont.systemFont(ofSize: 18),
                    .paragraphStyle: paragraphStyle
                ], range: NSRange(location: 0, length: attributed.length))
                textView.attributedText = attributed
            } else {
                textView.text = readingText
            }
        } else {
            textView.text = readingText
        }

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [textView, closeButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}
