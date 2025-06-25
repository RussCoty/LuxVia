import UIKit

class MiniPlayerContainerViewController: UIViewController {

    private let playerView = PlayerControlsView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        setupPlayer()
    }

    private func setupPlayer() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
