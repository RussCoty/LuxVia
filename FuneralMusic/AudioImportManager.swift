// AudioImportManager.swift
import UIKit
import UniformTypeIdentifiers

class AudioImportManager: NSObject, UIDocumentPickerDelegate {

    static let shared = AudioImportManager()
    private weak var presenter: UIViewController?

    static func presentImportPicker(from viewController: UIViewController) {
        shared.presenter = viewController

        let mp3Type = UTType(filenameExtension: "mp3")!
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [mp3Type], asCopy: true)
        picker.delegate = shared
        picker.allowsMultipleSelection = false
        viewController.present(picker, animated: true)
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if let nav = presenter?.navigationController,
           let mainVC = nav.viewControllers.first(where: { $0 is MainViewController }) as? MainViewController {
            mainVC.selectSegment(index: 1) // Return to Library
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else { return }

        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let importedFolderURL = docsURL.appendingPathComponent("audio/imported")

        do {
            if !fileManager.fileExists(atPath: importedFolderURL.path) {
                try fileManager.createDirectory(at: importedFolderURL, withIntermediateDirectories: true)
            }

            let destinationURL = importedFolderURL.appendingPathComponent(pickedURL.lastPathComponent)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.copyItem(at: pickedURL, to: destinationURL)

            if let nav = presenter?.navigationController,
               let mainVC = nav.viewControllers.first(where: { $0 is MainViewController }) as? MainViewController {
                mainVC.selectSegment(index: 1) // 1 = Library
            }
        } catch {
            print("❌ Failed to import: \(error)")
        }
    }
}
