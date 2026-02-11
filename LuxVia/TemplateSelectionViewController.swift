//
//  TemplateSelectionViewController.swift
//  LuxVia
//
//  View controller for selecting and applying funeral service templates
//

import UIKit

class TemplateSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var templates: [ServiceTemplate] = []
    private var selectedTemplate: ServiceTemplate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Service Templates"
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
        loadTemplates()
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Apply",
            style: .done,
            target: self,
            action: #selector(applyTapped)
        )
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TemplateCell.self, forCellReuseIdentifier: "TemplateCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadTemplates() {
        templates = TemplateManager.shared.getAvailableTemplates()
        tableView.reloadData()
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func applyTapped() {
        guard let template = selectedTemplate else { return }
        
        let hasExistingItems = !ServiceOrderManager.shared.items.isEmpty
        
        if hasExistingItems {
            let alert = UIAlertController(
                title: "Replace Existing Service?",
                message: "You have items in your current service. Do you want to replace them with this template, or add the template items to your existing service?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Replace", style: .destructive) { [weak self] _ in
                self?.applyTemplate(clearExisting: true)
            })
            
            alert.addAction(UIAlertAction(title: "Add to Existing", style: .default) { [weak self] _ in
                self?.applyTemplate(clearExisting: false)
            })
            
            present(alert, animated: true)
        } else {
            applyTemplate(clearExisting: true)
        }
    }
    
    private func applyTemplate(clearExisting: Bool) {
        guard let template = selectedTemplate else { return }
        
        TemplateManager.shared.applyTemplate(template, clearExisting: clearExisting)
        
        let alert = UIAlertController(
            title: "Template Applied",
            message: "The \(template.name) template has been applied to your service. You can now customize it by editing, reordering, or adding items.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TemplateCell", for: indexPath) as! TemplateCell
        let template = templates[indexPath.row]
        
        cell.configure(with: template)
        cell.accessoryType = template.id == selectedTemplate?.id ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Choose a template to start planning your service"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Templates provide a starting point with traditional sections and items. You can customize all items after applying the template."
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTemplate = templates[indexPath.row]
        navigationItem.rightBarButtonItem?.isEnabled = true
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Show preview
        showTemplatePreview(templates[indexPath.row])
    }
    
    private func showTemplatePreview(_ template: ServiceTemplate) {
        let previewVC = TemplatePreviewViewController(template: template)
        navigationController?.pushViewController(previewVC, animated: true)
    }
}

// MARK: - Template Cell

class TemplateCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let traditionLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 0
        
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        
        traditionLabel.font = .systemFont(ofSize: 12)
        traditionLabel.textColor = .tertiaryLabel
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, traditionLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with template: ServiceTemplate) {
        titleLabel.text = template.name
        descriptionLabel.text = template.description
        traditionLabel.text = "Tradition: \(template.tradition.rawValue)"
    }
}
