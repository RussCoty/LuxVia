import UIKit

class CustomReadingEditorViewController: UIViewController {

    private let titleField = UITextField()
    private let readByField = UITextField()
    private let bodyTextView = UITextView()
    private let addToServiceButton = UIButton(type: .system)

    var onSave: ((CustomReading) -> Void)?
    var onAddToService: ((CustomReading) -> Void)?
    private var editingReadingID: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Custom Reading"
        view.backgroundColor = .systemBackground
        setupForm()
        setupNavigation()
        setupAddToServiceButton()
    }

    private func setupForm() {
        titleField.placeholder = "Title"
        titleField.borderStyle = .roundedRect

        readByField.placeholder = "Read By"
        readByField.borderStyle = .roundedRect

        bodyTextView.layer.borderColor = UIColor.systemGray4.cgColor
        bodyTextView.layer.borderWidth = 1
        bodyTextView.layer.cornerRadius = 8
        bodyTextView.font = UIFont.systemFont(ofSize: 16)

        let stack = UIStackView(arrangedSubviews: [titleField, readByField, bodyTextView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bodyTextView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }

    private func setupAddToServiceButton() {
        addToServiceButton.setTitle("➕ Add to Service", for: .normal)
        addToServiceButton.setTitleColor(.systemBlue, for: .normal)
        addToServiceButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        addToServiceButton.addTarget(self, action: #selector(addToServiceTapped), for: .touchUpInside)
        addToServiceButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(addToServiceButton)

        NSLayoutConstraint.activate([
            addToServiceButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addToServiceButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func saveTapped() {
        guard let reading = buildReading() else { return }
        onSave?(reading)
        navigationController?.popViewController(animated: true)
    }

    @objc private func addToServiceTapped() {
        guard let reading = buildReading() else { return }

        let store = CustomReadingStore.shared
        if store.load().contains(where: { $0.id == reading.id }) {
            store.update(reading.id, with: reading)
        } else {
            store.add(reading)
        }

        let serviceItem = ServiceItem(
            type: .customReading,
            title: reading.title,
            subtitle: nil,
            customText: reading.content
        )

        ServiceOrderManager.shared.add(serviceItem) // 👈 Always add here

        onAddToService?(reading)
        navigationController?.popViewController(animated: true)
    }


    func setReading(_ reading: CustomReading) {
        editingReadingID = reading.id
        titleField.text = reading.title
        let parts = reading.content.components(separatedBy: "\n\n")
        if parts.count >= 2 {
            readByField.text = parts[0].replacingOccurrences(of: "Read by: ", with: "")
            bodyTextView.text = parts[1]
        } else {
            bodyTextView.text = reading.content
        }
    }

    private func buildReading() -> CustomReading? {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let readBy = readByField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = bodyTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty, !body.isEmpty else {
            let alert = UIAlertController(
                title: "Missing Info",
                message: "Please fill in title and body.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return nil
        }

        let content = "Read by: \(readBy)\n\n\(body)"
        return CustomReading(id: editingReadingID ?? UUID(), title: title, content: content)
    }
}
