import UIKit

class WordsListViewController: UITableViewController {

    private var lyrics: [LyricEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Words"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.lyrics = LyricsSyncManager.shared.loadCachedLyrics()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lyrics.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = lyrics[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = lyrics[indexPath.row]
        let detailVC = LyricsDetailViewController(entry: entry)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

