//
//  TemplatePreviewViewController.swift
//  LuxVia
//
//  Shows a preview of a service template's structure
//

import UIKit

class TemplatePreviewViewController: UIViewController, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let template: ServiceTemplate
    
    init(template: ServiceTemplate) {
        self.template = template
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = template.name
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return template.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return template.sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = template.sections[indexPath.section].items[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        
        let optionalSuffix = item.isOptional ? " (Optional)" : ""
        config.text = item.title + optionalSuffix
        
        if let subtitle = item.subtitle {
            config.secondaryText = subtitle
        } else if let customText = item.customText {
            let preview = String(customText.prefix(60))
            config.secondaryText = preview + (customText.count > 60 ? "..." : "")
        }
        
        config.secondaryTextProperties.numberOfLines = 2
        config.secondaryTextProperties.color = .secondaryLabel
        
        // Add type indicator
        let typeEmoji: String
        switch item.type {
        case .song, .music:
            typeEmoji = "🎵"
        case .reading:
            typeEmoji = "📖"
        case .welcome:
            typeEmoji = "👋"
        case .farewell:
            typeEmoji = "🙏"
        case .customReading:
            typeEmoji = "📝"
        case .background:
            typeEmoji = "🎶"
        }
        
        config.text = "\(typeEmoji) " + (config.text ?? "")
        
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return template.sections[section].title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == template.sections.count - 1 {
            return "This preview shows the template structure. Items marked (Optional) can be included or removed based on your preferences."
        }
        return nil
    }
}
