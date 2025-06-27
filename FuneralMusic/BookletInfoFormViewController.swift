// File: BookletInfoFormViewController.swift

import UIKit

class BookletInfoFormViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var selectedImageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Booklet Details"
        setupScrollView()
        buildFormFields()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 12
    }

    private func buildFormFields() {
        addSectionTitle("Your Details")
        addTextField(placeholder: "Your Name")
        addTextField(placeholder: "Your Email")

        addSectionTitle("Deceased Details")
        addTextField(placeholder: "Full Name of Deceased")
        addDatePicker(title: "Date of Birth")
        addDatePicker(title: "Date of Passing")
        addPhotoUploader()

        addSectionTitle("Service Details")
        addTextField(placeholder: "Location of Service")
        addDatePicker(title: "Date of Service")
        addTimePicker(title: "Time of Service")
        addTextField(placeholder: "Minister/Celebrant Name")

        addSectionTitle("Committal & Wake")
        addTextField(placeholder: "Committal Location")
        addTextField(placeholder: "Wake/Reception Location")

        addSectionTitle("Flowers / Donations")
        addTextView(placeholder: "Donation/Flower Instructions")

        addSectionTitle("Additional Info")
        addTextField(placeholder: "Photographer Name")
        addTextField(placeholder: "Pallbearers")

        addSaveButton()
    }

    private func addSectionTitle(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .boldSystemFont(ofSize: 18)
        stackView.addArrangedSubview(label)
    }

    private func addTextField(placeholder: String) {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        stackView.addArrangedSubview(field)
    }

    private func addTextView(placeholder: String) {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.text = placeholder
        textView.textColor = .placeholderText
        textView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        stackView.addArrangedSubview(textView)
    }

    private func addDatePicker(title: String) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact

        let container = UIStackView(arrangedSubviews: [label, datePicker])
        container.axis = .vertical
        container.spacing = 4
        stackView.addArrangedSubview(container)
    }

    private func addPhotoUploader() {
        selectedImageView = UIImageView()
        selectedImageView?.contentMode = .scaleAspectFit
        selectedImageView?.heightAnchor.constraint(equalToConstant: 120).isActive = true
        selectedImageView?.backgroundColor = .secondarySystemBackground
        stackView.addArrangedSubview(selectedImageView!)

        let button = UIButton(type: .system)
        button.setTitle("Upload Photograph", for: .normal)
        button.addTarget(self, action: #selector(handlePhotoUpload), for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    @objc private func handlePhotoUpload() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImageView?.image = image
        }
        dismiss(animated: true)
    }
    private func addTimePicker(title: String) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)

        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .compact

        let container = UIStackView(arrangedSubviews: [label, timePicker])
        container.axis = .vertical
        container.spacing = 4
        stackView.addArrangedSubview(container)
    }

    private func addSaveButton() {
        let button = UIButton(type: .system)
        button.setTitle("Save Booklet Info", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    @objc private func handleSave() {
        print("✅ Booklet info saved. (Implement persistence logic here.)")
    }
}
