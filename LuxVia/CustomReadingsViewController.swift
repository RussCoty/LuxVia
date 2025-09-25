import UIKit
import SwiftUI
//import MarkdownUI
// 

class CustomReadingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var customReadings: [CustomReading] = []
    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
        private let aiEulogyButton = UIButton(type: .system)
        private let recordButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        customReadings = CustomReadingStore.shared.load()
        
        setupAddButton()
            setupAIEulogyButton()
            setupRecordButton()
        setupTableView()
    }
    
    private func setupAddButton() {
        addButton.setTitle("➕ Add Custom Reading", for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        addButton.addTarget(self, action: #selector(addReading), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

        private func setupAIEulogyButton() {
            aiEulogyButton.setTitle("🧠 Write Eulogy with AI", for: .normal)
            aiEulogyButton.setTitleColor(.systemPurple, for: .normal)
            aiEulogyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            aiEulogyButton.addTarget(self, action: #selector(openAIEulogyWriter), for: .touchUpInside)
            aiEulogyButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(aiEulogyButton)
            NSLayoutConstraint.activate([
                aiEulogyButton.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 12),
                aiEulogyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    
        private func setupRecordButton() {
            recordButton.setTitle("🎤 Record Custom Reading", for: .normal)
            recordButton.setTitleColor(.systemBlue, for: .normal)
            recordButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            recordButton.addTarget(self, action: #selector(recordCustomReading), for: .touchUpInside)
            recordButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(recordButton)
            NSLayoutConstraint.activate([
                recordButton.topAnchor.constraint(equalTo: aiEulogyButton.bottomAnchor, constant: 12),
                recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    
    @objc private func openAIEulogyWriter() {
        let vc = UIHostingController(rootView: EulogyWriterView.make())
        navigationController?.pushViewController(vc, animated: true)
    }
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
        @objc private func recordCustomReading() {
            let recorderVC = UIHostingController(rootView: WordRecorderView())
            navigationController?.pushViewController(recorderVC, animated: true)
        }
    @objc private func addReading() {
        let editorVC = CustomReadingEditorViewController()
        
        editorVC.onSave = { [weak self] newReading in
            // Save only on manual Save
            CustomReadingStore.shared.add(newReading)
            self?.customReadings = CustomReadingStore.shared.load()
            self?.tableView.reloadData()
        }
        
        editorVC.onAddToService = { [weak self] reading in
            // ❌ DO NOT save again here!
            self?.customReadings = CustomReadingStore.shared.load()
            self?.tableView.reloadData()
            
            let serviceItem = ServiceItem(
                type: .customReading,
                title: reading.title,
                subtitle: nil,
                customText: reading.content
            )
            
            ServiceOrderManager.shared.add(serviceItem)
            self?.tabBarController?.selectedIndex = 0
        }
        
        navigationController?.pushViewController(editorVC, animated: true)
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        customReadings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reading = customReadings[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = reading.title
        
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add to Service", for: .normal)
        addButton.tag = indexPath.row
        addButton.addTarget(self, action: #selector(addToService(_:)), for: .touchUpInside)
        cell.accessoryView = addButton
        
        return cell
    }
    
    // MARK: - Add to Service
    
    @objc private func addToService(_ sender: UIButton) {
        let reading = customReadings[sender.tag]
        let serviceItem = ServiceItem(
            type: .customReading,
            title: reading.title,
            subtitle: nil,
            customText: reading.content
        )
        print("Adding to service:", serviceItem)
        ServiceOrderManager.shared.add(serviceItem)
    }
    
    // MARK: - UITableView Editing
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let reading = customReadings[indexPath.row]
            CustomReadingStore.shared.remove(id: reading.id)
            customReadings.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: - UITableView Selection
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reading = customReadings[indexPath.row]
        let editorVC = CustomReadingEditorViewController()
        editorVC.setReading(reading)
        editorVC.onSave = { [weak self] updated in
            CustomReadingStore.shared.update(updated.id, with: updated)
            self?.customReadings = CustomReadingStore.shared.load()
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(editorVC, animated: true)
    }
    
    
}
