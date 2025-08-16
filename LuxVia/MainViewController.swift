import UIKit
import Foundation

class MainViewController: BaseViewController {
    // Programmatically select a segment in the segmented control
    // Called when Edit button is tapped in Library segment
    // Toggles editing mode in MusicViewController, enabling red minus delete for imported audio
    @objc func editButtonTapped() {
        libraryVC.isEditingLibrary.toggle()
        libraryVC.tableView.setEditing(libraryVC.isEditingLibrary, animated: true)
        editButton?.title = libraryVC.isEditingLibrary ? "Done" : "Edit"
        libraryVC.tableView.reloadData() // Ensure table view reloads to update delete controls
    }
    // Edit button for toggling Music Library editing mode
    var editButton: UIBarButtonItem?
    
    let segmentedControl = UISegmentedControl(items: ["Import", "Library"])
    private let containerView = UIView()
    
    let libraryVC = MusicViewController()
    //let playlistVC = ServiceViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Music"
        
        print("🔍 isLoggedIn =", AuthManager.shared.isLoggedIn)
        print("📍 MainViewController loaded")
        
        
        setupUI()
        
        showLibrary()
        
        //MiniPlayerManager.shared.attach(to: self) // ✅ Correct usage
        
    }
    
    
    
    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -250)
        ])
        
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl

    // Setup Edit button for Library segment only
    // The button toggles editing mode in MusicViewController (for imported audio deletion)
    editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonTapped))
    navigationItem.leftBarButtonItem = segmentedControl.selectedSegmentIndex == 1 ? editButton : nil
    }
    
    
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: AudioImportManager.presentImportPicker(from: self)
        case 1: showLibrary()
            // case 2: showPlaylist()
        default: break
        }
    // Show Edit button only for Library segment
    // Hide for Import segment
    navigationItem.leftBarButtonItem = sender.selectedSegmentIndex == 1 ? editButton : nil
    }
    
    @objc func selectSegment(index: Int) {
        segmentedControl.selectedSegmentIndex = index
        segmentChanged(segmentedControl)
    }
    
    private func showLibrary() {
        swapChild(to: libraryVC)
    }
    
    
    private func swapChild(to newVC: UIViewController) {
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        addChild(newVC)
        containerView.addSubview(newVC.view)
        newVC.view.frame = containerView.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newVC.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MiniPlayerManager.shared.syncPlayerUI()
        
        
    }
}
