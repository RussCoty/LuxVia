// File: BookletInfoFormViewController.swift

import UIKit

class BookletInfoFormViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var keyboardVisible = false
    private var originalInset: UIEdgeInsets = .zero

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var selectedImageView: UIImageView?
    private var bookletInfo = BookletInfo.load() ?? BookletInfo(
        userName: "",
        userEmail: "",
        deceasedName: "",
        dateOfBirth: Date(),
        dateOfPassing: Date(),
        photo: nil,
        location: "",
        dateOfService: Date(),
        timeHour: 10,
        timeMinute: 30,
        celebrantName: "",
        committalLocation: nil,
        wakeLocation: nil,
        donationInfo: nil,
        pallbearers: nil,
        photographer: nil
        , announcementText: nil
    )

    // Announcement UI
    private var announcementContainer: UIView?
    private var announcementTextView: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Booklet Details"
        setupScrollView()
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)

        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        buildFormFields()
    }
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard !keyboardVisible,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        keyboardVisible = true
        originalInset = scrollView.contentInset

        let bottomInset = keyboardFrame.height + 20
        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        guard keyboardVisible else { return }

        scrollView.contentInset = originalInset
        scrollView.scrollIndicatorInsets = originalInset
        keyboardVisible = false
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

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
        addTextField(placeholder: "Your Name", text: bookletInfo.userName)
        addTextField(placeholder: "Your Email", text: bookletInfo.userEmail)

        addSectionTitle("Deceased Details")
        addTextField(placeholder: "Full Name of Deceased", text: bookletInfo.deceasedName)
        addDatePicker(title: "Date of Birth", date: bookletInfo.dateOfBirth)
        addDatePicker(title: "Date of Passing", date: bookletInfo.dateOfPassing)
        addPhotoUploader()

        addSectionTitle("Service Details")
        addTextField(placeholder: "Location of Service", text: bookletInfo.location)
        addDatePicker(title: "Date of Service", date: bookletInfo.dateOfService)
        addTimePicker(title: "Time of Service", hour: bookletInfo.timeHour, minute: bookletInfo.timeMinute)
        addTextField(placeholder: "Minister/Celebrant Name", text: bookletInfo.celebrantName)

        addSectionTitle("Committal & Wake")
        addTextField(placeholder: "Committal Location", text: bookletInfo.committalLocation)
        addTextField(placeholder: "Wake/Reception Location", text: bookletInfo.wakeLocation)

        addSectionTitle("Flowers / Donations")
        addTextView(placeholder: "Donation/Flower Instructions", text: bookletInfo.donationInfo)

        addSectionTitle("Additional Info")
        addTextField(placeholder: "Photographer Name", text: bookletInfo.photographer)
        addTextField(placeholder: "Pallbearers", text: bookletInfo.pallbearers)

        addSaveButton()
        addAnnouncementContainer() // create but keep hidden until save
    }

    private func addSectionTitle(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .boldSystemFont(ofSize: 18)
        stackView.addArrangedSubview(label)
    }

    private func addTextField(placeholder: String, text: String? = nil) {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.text = text
        stackView.addArrangedSubview(field)
    }

    private func addTextView(placeholder: String, text: String? = nil) {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.text = text ?? placeholder
        textView.textColor = text == nil ? .placeholderText : .label
        textView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        stackView.addArrangedSubview(textView)
    }

    private func addAnnouncementContainer() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "Announcement"
        title.font = .boldSystemFont(ofSize: 18)

        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        textView.textColor = .label

        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy Text", for: .normal)
        copyButton.addTarget(self, action: #selector(handleCopyAnnouncement), for: .touchUpInside)

        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export PDF", for: .normal)
        exportButton.addTarget(self, action: #selector(handleExportAnnouncement), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [copyButton, exportButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let vstack = UIStackView(arrangedSubviews: [title, textView, buttonStack])
        vstack.axis = .vertical
        vstack.spacing = 8

        container.addSubview(vstack)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: container.topAnchor),
            vstack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vstack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vstack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        container.isHidden = true
        stackView.addArrangedSubview(container)

        self.announcementContainer = container
        self.announcementTextView = textView
    }

    private func addDatePicker(title: String, date: Date) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.date = date

        let container = UIStackView(arrangedSubviews: [label, datePicker])
        container.axis = .vertical
        container.spacing = 4
        stackView.addArrangedSubview(container)
    }

    private func addTimePicker(title: String, hour: Int, minute: Int) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)

        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .compact
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        timePicker.date = Calendar.current.date(from: components) ?? Date()

        let container = UIStackView(arrangedSubviews: [label, timePicker])
        container.axis = .vertical
        container.spacing = 4
        stackView.addArrangedSubview(container)
    }

    private func addPhotoUploader() {
        selectedImageView = UIImageView()
        selectedImageView?.contentMode = .scaleAspectFit
        selectedImageView?.heightAnchor.constraint(equalToConstant: 120).isActive = true
        selectedImageView?.backgroundColor = .secondarySystemBackground
        if let data = bookletInfo.photo, let image = UIImage(data: data) {
            selectedImageView?.image = image
        }
        stackView.addArrangedSubview(selectedImageView!)

        let button = UIButton(type: .system)
        button.setTitle("Add Photograph", for: .normal)
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
        if let image = selectedImageView?.image {
            bookletInfo.photo = image.jpegData(compressionQuality: 0.8)
        }

        for view in stackView.arrangedSubviews {
            if let textField = view as? UITextField {
                switch textField.placeholder {
                case "Your Name":
                    bookletInfo.userName = textField.text ?? ""
                case "Your Email":
                    bookletInfo.userEmail = textField.text ?? ""
                case "Full Name of Deceased":
                    bookletInfo.deceasedName = textField.text ?? ""
                case "Location of Service":
                    bookletInfo.location = textField.text ?? ""
                case "Minister/Celebrant Name":
                    bookletInfo.celebrantName = textField.text ?? ""
                case "Committal Location":
                    bookletInfo.committalLocation = textField.text
                case "Wake/Reception Location":
                    bookletInfo.wakeLocation = textField.text
                case "Photographer Name":
                    bookletInfo.photographer = textField.text
                case "Pallbearers":
                    bookletInfo.pallbearers = textField.text
                default:
                    break
                }
            }

            if let textView = view as? UITextView, textView.textColor != .placeholderText {
                bookletInfo.donationInfo = textView.text
            }

            if let container = view as? UIStackView {
                for inner in container.arrangedSubviews {
                    if let dp = inner as? UIDatePicker {
                        switch (container.arrangedSubviews.first as? UILabel)?.text {
                        case "Date of Birth":
                            bookletInfo.dateOfBirth = dp.date
                        case "Date of Passing":
                            bookletInfo.dateOfPassing = dp.date
                        case "Date of Service":
                            bookletInfo.dateOfService = dp.date
                        case "Time of Service":
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: dp.date)
                            bookletInfo.timeHour = comps.hour ?? 10
                            bookletInfo.timeMinute = comps.minute ?? 30
                        default:
                            break
                        }
                    }
                }
            }
        }

        bookletInfo.save()
        print("✅ Booklet info saved.")
        showToast("Booklet info saved")

        // Ensure announcement box appears after save
        DispatchQueue.main.async {
            self.presentAnnouncementIfNeeded()
        }

    }

    private func presentAnnouncementIfNeeded() {
        // Always regenerate announcement to reflect current form data
        // User can still manually edit it afterwards
        bookletInfo.announcementText = generateAnnouncementText(from: bookletInfo)
        bookletInfo.save()

        if let container = announcementContainer, let tv = announcementTextView {
            tv.text = bookletInfo.announcementText
            container.isHidden = false
        }
    }

    private func generateAnnouncementText(from info: BookletInfo) -> String {
        let dateFmt = DateFormatter(); dateFmt.dateStyle = .long
        let dob = dateFmt.string(from: info.dateOfBirth)
        let dop = dateFmt.string(from: info.dateOfPassing)
        var comps = DateComponents(); comps.hour = info.timeHour; comps.minute = info.timeMinute
        let timeFmt = DateFormatter(); timeFmt.timeStyle = .short
        let timeDate = Calendar.current.date(from: comps) ?? info.dateOfService

        var lines: [String] = []
        lines.append("It is with great sadness that we announce the passing of \(info.deceasedName).")
        lines.append("Born: \(dob). Passed away: \(dop).")
        lines.append("A service will be held at \(info.location) on \(dateFmt.string(from: info.dateOfService)) at \(timeFmt.string(from: timeDate)).")
        if !info.celebrantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Officiant: \(info.celebrantName).")
        }
        if let comm = info.committalLocation, !comm.isEmpty {
            lines.append("Committal: \(comm).")
        }
        return lines.joined(separator: "\n\n")
    }

    @objc private func handleCopyAnnouncement() {
        guard let text = announcementTextView?.text, !text.isEmpty else { return }
        UIPasteboard.general.string = text
        showToast("Announcement copied")
        // persist the edited announcement
        bookletInfo.announcementText = text
        bookletInfo.save()
    }

    @objc private func handleExportAnnouncement() {
        guard let text = announcementTextView?.text, !text.isEmpty else { return }
        bookletInfo.announcementText = text
        bookletInfo.save()

        DispatchQueue.global(qos: .userInitiated).async {
            if let url = PDFBookletGenerator.generateAnnouncementPDF(info: self.bookletInfo, announcement: text) {
                DispatchQueue.main.async {
                    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    av.popoverPresentationController?.sourceView = self.view
                    self.present(av, animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self.showToast("Failed to create PDF")
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📘 BookletInfoFormViewController appeared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !(UIApplication.shared.windows.first?.rootViewController is MainTabBarController &&
                  (UIApplication.shared.windows.first?.rootViewController as? MainTabBarController)?.selectedIndex == 0) {
                if !UIApplication.isServiceTabActive() {
                    MiniPlayerManager.shared.setVisible(false)
                }
            }
        }
    }
    private func showToast(_ message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.backgroundColor = UIColor.systemGreen
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 6
        toastLabel.clipsToBounds = true
        toastLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let padding: CGFloat = 12
        toastLabel.frame = CGRect(
            x: padding,
            y: view.safeAreaInsets.top + 16,
            width: view.frame.width - padding * 2,
            height: 36
        )
        view.addSubview(toastLabel)

        UIView.animate(withDuration: 0.25, animations: {
            toastLabel.alpha = 1.0
            toastLabel.transform = .identity
        }) { _ in
            UIView.animate(
                withDuration: 0.25,
                delay: 2.0,
                options: .curveEaseInOut,
                animations: {
                    toastLabel.alpha = 0.0
                    toastLabel.transform = CGAffineTransform(translationX: 0, y: -10)
                }, completion: { _ in
                    toastLabel.removeFromSuperview()
                }
            )
        }
    }

}
