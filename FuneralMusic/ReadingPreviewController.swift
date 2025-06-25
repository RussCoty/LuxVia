import UIKit

class ReadingPreviewViewController: UIViewController {

    private let readingTitle: String
    private let readingText: String

    init(title: String, text: String) {
        self.readingTitle = title
        self.readingText = text
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = readingTitle

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.textAlignment = .center
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16)
        textView.backgroundColor = .clear

        if let data = readingText.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                // Beware below commenting
                //.documentType: .html,
                
                .documentType: NSAttributedString.DocumentType.html,

                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                style.paragraphSpacing = 8
                attributed.addAttributes([
                    .font: UIFont.systemFont(ofSize: 18),
                    .paragraphStyle: style
                ], range: NSRange(location: 0, length: attributed.length))
                textView.attributedText = attributed
            } else {
                textView.text = readingText
            }
        } else {
            textView.text = readingText
        }

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
