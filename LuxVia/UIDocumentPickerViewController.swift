//
//  UIDocumentPickerViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 17/05/2025.
//

import UIKit
import UniformTypeIdentifiers

class ImportViewController: UIViewController, UIDocumentPickerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        pickMP3File()
    }

    func pickMP3File() {
        let mp3Type = UTType(filenameExtension: "mp3")!
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [mp3Type], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else { return }
        saveMP3ToImportedFolder(fileURL: pickedURL)
    }

    func saveMP3ToImportedFolder(fileURL: URL) {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let importedFolderURL = docsURL.appendingPathComponent("audio/imported")

        if !fileManager.fileExists(atPath: importedFolderURL.path) {
            try? fileManager.createDirectory(at: importedFolderURL, withIntermediateDirectories: true)
        }

        let destinationURL = importedFolderURL.appendingPathComponent(fileURL.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            print("Saved MP3 to: \(destinationURL.path)")
        } catch {
            print("Failed to copy file: \(error)")
        }
    }
}
