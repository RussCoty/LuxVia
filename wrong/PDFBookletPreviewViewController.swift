// File: Controllers/PDFBookletPreviewViewController.swift

import UIKit
import PDFKit

class PDFBookletPreviewViewController: UIViewController {

    private let pdfView = PDFView()
    private var pdfData: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Booklet Preview"
        setupPDFView()
        setupDownloadButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        regeneratePDF()
    }

    private func setupPDFView() {
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        view.addSubview(pdfView)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
        ])
    }

    private func setupDownloadButton() {
        let button = UIButton(type: .system)
        button.setTitle("Download PDF", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    @objc func regeneratePDF() {
        let info = BookletInfo.load() ?? BookletInfo(
            userName: "", userEmail: "",
            deceasedName: "", dateOfBirth: Date(), dateOfPassing: Date(), photo: nil,
            location: "", dateOfService: Date(), timeHour: 0, timeMinute: 0, celebrantName: "",
            committalLocation: nil, wakeLocation: nil, donationInfo: nil, pallbearers: nil, photographer: nil
        )

        var finalItems = [ServiceItem]()
        
        SharedLibraryManager.shared.preloadAllReadings()

        for item in ServiceOrderManager.shared.items {
            finalItems.append(item)

            if [.song, .music, .background].contains(item.type),
               let fileName = item.fileName?.normalizedFilename {

                if let lyric = SharedLibraryManager.shared.allReadings.first(where: {
                    $0.audioFileName?.normalizedFilename == fileName && !$0.body.isEmpty
                }) {
                    let lyricItem = ServiceItem(
                        type: .customReading,
                        title: "Lyrics: \(lyric.title)",
                        fileName: lyric.audioFileName,
                        customText: lyric.body
                    )
                    finalItems.append(lyricItem)
                }
            }
        }

        if let fileURL = PDFBookletGenerator.generate(from: info, items: finalItems),
           let data = try? Data(contentsOf: fileURL) {
            self.pdfData = data
            self.pdfView.document = PDFDocument(data: data)
        } else {
            print("❌ Failed to regenerate PDF preview")
        }
    }

    @objc private func handleDownload() {
        guard let data = pdfData else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Booklet.pdf")
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            present(activityVC, animated: true)
        } catch {
            print("❌ Failed to save temp PDF: \(error)")
        }
    }
}
