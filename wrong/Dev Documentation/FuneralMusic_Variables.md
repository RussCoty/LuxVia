# 📊 Variable Reference Guide

| File | Declaration | Purpose (Fill-in) |
|------|-------------|--------------------|
| `ViewController.swift` | `var webView: WKWebView!` | _TBD_ |
| `ViewController.swift` | `let statusLabel = UILabel()` | _TBD_ |
| `ViewController.swift` | `let customCSS = """` | _TBD_ |
| `ViewController.swift` | `let scriptSource = "var style = document.createElement('style'); style.innerHTML = `\(customCSS)`; document.head.appendChild(style);"` | _TBD_ |
| `ViewController.swift` | `let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)` | _TBD_ |
| `ViewController.swift` | `let contentController = WKUserContentController()` | _TBD_ |
| `ViewController.swift` | `let config = WKWebViewConfiguration()` | _TBD_ |
| `ViewController.swift` | `let request = URLRequest(url: url)` | _TBD_ |
| `ViewController.swift` | `let isMember = UserDefaults.standard.bool(forKey: "isMember")` | _TBD_ |
| `ViewController.swift` | `var request = URLRequest(url: url)` | _TBD_ |
| `ViewController.swift` | `let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {` | _TBD_ |
| `ViewController.swift` | `let isMember = json["is_member"] as? Bool ?? false` | _TBD_ |
| `AudioPlayerManager.swift` | `var player: AVAudioPlayer?` | _TBD_ |
| `AudioPlayerManager.swift` | `var isPaused: Bool {` | _TBD_ |
| `AudioPlayerManager.swift` | `var isStopped: Bool {` | _TBD_ |
| `AudioPlayerManager.swift` | `var currentSource: AudioSource = .none` | _TBD_ |
| `AudioPlayerManager.swift` | `var currentTrackName: String?` | _TBD_ |
| `AudioPlayerManager.swift` | `var volume: Float = 0.75 {` | _TBD_ |
| `AudioPlayerManager.swift` | `var cuedTrackName: String?` | _TBD_ |
| `AudioPlayerManager.swift` | `var cuedSource: AudioSource = .none` | _TBD_ |
| `AudioPlayerManager.swift` | `var isTrackCued: Bool {` | _TBD_ |
| `AudioPlayerManager.swift` | `var currentTime: TimeInterval {` | _TBD_ |
| `AudioPlayerManager.swift` | `var duration: TimeInterval {` | _TBD_ |
| `AudioPlayerManager.swift` | `var isPlaying: Bool {` | _TBD_ |
| `AudioPlayerManager.swift` | `let fileManager = FileManager.default` | _TBD_ |
| `AudioPlayerManager.swift` | `let importedURL = docsURL.appendingPathComponent("audio/imported/\(name).mp3")` | _TBD_ |
| `AudioPlayerManager.swift` | `let trackName = url.deletingPathExtension().lastPathComponent` | _TBD_ |
| `AudioPlayerManager.swift` | `let displayName = trackName.replacingOccurrences(of: "_", with: " ").capitalized` | _TBD_ |
| `AudioPlayerManager.swift` | `let playNow = {` | _TBD_ |
| `AudioPlayerManager.swift` | `let isMember = UserDefaults.standard.bool(forKey: "isMember")` | _TBD_ |
| `AuthManager.swift` | `var isLoggedIn: Bool {` | _TBD_ |
| `BaseViewController.swift` | `let header = UIView()` | _TBD_ |
| `KeychainHelper.swift` | `let query: [String: Any] = [` | _TBD_ |
| `KeychainHelper.swift` | `let query: [String: Any] = [` | _TBD_ |
| `KeychainHelper.swift` | `var result: AnyObject?` | _TBD_ |
| `KeychainHelper.swift` | `let query: [String: Any] = [` | _TBD_ |
| `LibraryViewController.swift` | `let tableView = UITableView(frame: .zero, style: .insetGrouped)` | _TBD_ |
| `LibraryViewController.swift` | `let searchController = UISearchController(searchResultsController: nil)` | _TBD_ |
| `LibraryViewController.swift` | `var groupedTracks: [String: [String]] = [:]` | _TBD_ |
| `LibraryViewController.swift` | `var sortedFolders: [String] = []` | _TBD_ |
| `LibraryViewController.swift` | `var collapsedSections: Set<String> = []` | _TBD_ |
| `LibraryViewController.swift` | `var filteredGroupedTracks: [String: [String]] = [:]` | _TBD_ |
| `LibraryViewController.swift` | `var filteredFolders: [String] = []` | _TBD_ |
| `LibraryViewController.swift` | `var isFiltering: Bool {` | _TBD_ |
| `LibraryViewController.swift` | `let query = searchController.searchBar.text?.lowercased() ?? ""` | _TBD_ |
| `LibraryViewController.swift` | `var temp: [String: [String]] = [:]` | _TBD_ |
| `LibraryViewController.swift` | `let matches = tracks.filter { $0.lowercased().contains(query) }` | _TBD_ |
| `LibraryViewController.swift` | `let fileManager = FileManager.default` | _TBD_ |
| `LibraryViewController.swift` | `var tempGroups: [String: [String]] = [:]` | _TBD_ |
| `LibraryViewController.swift` | `let relativePath = fileURL.path.replacingOccurrences(of: bundleAudioURL.path + "/", with: "")` | _TBD_ |
| `LibraryViewController.swift` | `let components = relativePath.components(separatedBy: "/")` | _TBD_ |
| `LibraryViewController.swift` | `let rawFolder = components.dropLast().joined(separator: "/")` | _TBD_ |
| `LibraryViewController.swift` | `let folder = rawFolder.isEmpty ? "Music" : rawFolder.capitalized` | _TBD_ |
| `LibraryViewController.swift` | `let name = fileURL.deletingPathExtension().lastPathComponent` | _TBD_ |
| `LibraryViewController.swift` | `let importedURL = docsURL.appendingPathComponent("audio")` | _TBD_ |
| `LibraryViewController.swift` | `let relativePath = fileURL.path.replacingOccurrences(of: importedURL.path + "/", with: "")` | _TBD_ |
| `LibraryViewController.swift` | `let components = relativePath.components(separatedBy: "/")` | _TBD_ |
| `LibraryViewController.swift` | `let rawFolder = components.dropLast().joined(separator: "/")` | _TBD_ |
| `LibraryViewController.swift` | `let folder = rawFolder.isEmpty ? "Imported" : rawFolder.capitalized` | _TBD_ |
| `LibraryViewController.swift` | `let name = fileURL.deletingPathExtension().lastPathComponent` | _TBD_ |
| `LibraryViewController.swift` | `let mp3Type = UTType(filenameExtension: "mp3")!` | _TBD_ |
| `LibraryViewController.swift` | `let picker = UIDocumentPickerViewController(forOpeningContentTypes: [mp3Type], asCopy: true)` | _TBD_ |
| `LibraryViewController.swift` | `let fileManager = FileManager.default` | _TBD_ |
| `LibraryViewController.swift` | `let importedFolderURL = docsURL.appendingPathComponent("audio/imported")` | _TBD_ |
| `LibraryViewController.swift` | `let destinationURL = importedFolderURL.appendingPathComponent(pickedURL.lastPathComponent)` | _TBD_ |
| `LibraryViewController.swift` | `let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]` | _TBD_ |
| `LibraryViewController.swift` | `let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]` | _TBD_ |
| `LibraryViewController.swift` | `let isCollapsed = collapsedSections.contains(folder)` | _TBD_ |
| `LibraryViewController.swift` | `let icon = isCollapsed && !isFiltering ? "▶︎" : "▼"` | _TBD_ |
| `LibraryViewController.swift` | `let label = UILabel()` | _TBD_ |
| `LibraryViewController.swift` | `let tapView = UIView()` | _TBD_ |
| `LibraryViewController.swift` | `let container = UIView()` | _TBD_ |
| `LibraryViewController.swift` | `let folder = sortedFolders[section]` | _TBD_ |
| `LibraryViewController.swift` | `let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]` | _TBD_ |
| `LibraryViewController.swift` | `let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] ?? ""` | _TBD_ |
| `LibraryViewController.swift` | `let cell = UITableViewCell(style: .value1, reuseIdentifier: "TrackCell")` | _TBD_ |
| `LibraryViewController.swift` | `let addButton = UIButton(type: .contactAdd)` | _TBD_ |
| `LibraryViewController.swift` | `let audio = AudioPlayerManager.shared` | _TBD_ |
| `LibraryViewController.swift` | `let folder = isFiltering ? filteredFolders[indexPath.section] : sortedFolders[indexPath.section]` | _TBD_ |
| `LibraryViewController.swift` | `let track = (isFiltering ? filteredGroupedTracks : groupedTracks)[folder]?[indexPath.row] ?? ""` | _TBD_ |
| `LibraryViewController.swift` | `let section = sender.tag / 1000` | _TBD_ |
| `LibraryViewController.swift` | `let row = sender.tag % 1000` | _TBD_ |
| `LibraryViewController.swift` | `let folder = isFiltering ? filteredFolders[section] : sortedFolders[section]` | _TBD_ |
| `LibraryViewController.swift` | `let alert = UIAlertController(` | _TBD_ |
| `LibraryViewController.swift` | `let toast = PaddedLabel()` | _TBD_ |
| `LibraryViewController.swift` | `let menuButton = UIBarButtonItem(title: "⋯", style: .plain, target: self, action: #selector(showUserMenu))` | _TBD_ |
| `LibraryViewController.swift` | `let status = AuthManager.shared.isLoggedIn ? "Member: Active" : "Guest"` | _TBD_ |
| `LibraryViewController.swift` | `let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)` | _TBD_ |
| `LoginViewController.swift` | `var webView: WKWebView!` | _TBD_ |
| `LoginViewController.swift` | `var loginCheckTimer: Timer?` | _TBD_ |
| `LoginViewController.swift` | `let config = WKWebViewConfiguration()` | _TBD_ |
| `LoginViewController.swift` | `let request = URLRequest(url: url)` | _TBD_ |
| `LoginViewController.swift` | `var request = URLRequest(url: url)` | _TBD_ |
| `LoginViewController.swift` | `let config = URLSessionConfiguration.default` | _TBD_ |
| `LoginViewController.swift` | `let session = URLSession(configuration: config)` | _TBD_ |
| `LoginViewController.swift` | `let task = session.dataTask(with: request) { data, response, error in` | _TBD_ |
| `LoginViewController.swift` | `let isLoggedIn = json["is_logged_in"] as? Bool ?? false` | _TBD_ |
| `LoginViewController.swift` | `let isMember = json["is_member"] as? Bool ?? false` | _TBD_ |
| `LoginViewController.swift` | `let sceneDelegate = UIApplication.shared.connectedScenes` | _TBD_ |
| `MainViewController.swift` | `let segmentedControl = UISegmentedControl(items: ["Library", "Playlist"])` | _TBD_ |
| `MainViewController.swift` | `let alert = UIAlertController(` | _TBD_ |
| `MainViewController.swift` | `let audio = AudioPlayerManager.shared` | _TBD_ |
| `MainViewController.swift` | `let player = AudioPlayerManager.shared` | _TBD_ |
| `MainViewController.swift` | `let currentTime = Float(player.currentTime)` | _TBD_ |
| `MainViewController.swift` | `let duration = Float(player.duration)` | _TBD_ |
| `MainViewController.swift` | `let current = Int(AudioPlayerManager.shared.currentTime)` | _TBD_ |
| `MainViewController.swift` | `let duration = Int(AudioPlayerManager.shared.duration)` | _TBD_ |
| `MainViewController.swift` | `let nextTrack = SharedPlaylistManager.shared.playlist[currentTrackIndex]` | _TBD_ |
| `MainViewController.swift` | `let audio = AudioPlayerManager.shared` | _TBD_ |
| `MainViewController.swift` | `let fadeStep: Float = 0.01` | _TBD_ |
| `MainViewController.swift` | `let fadeDuration: TimeInterval = 1.5` | _TBD_ |
| `MainViewController.swift` | `let interval: TimeInterval = 0.01` | _TBD_ |
| `MainViewController.swift` | `let totalSteps = Int(fadeDuration / interval)` | _TBD_ |
| `MainViewController.swift` | `let volumeDecrement = audio.volume / Float(totalSteps)` | _TBD_ |
| `MainViewController.swift` | `let fadeTarget: Float = audio.volume` | _TBD_ |
| `MainViewController.swift` | `let fadeStep: Float = 0.01` | _TBD_ |
| `MainViewController.swift` | `let interval: TimeInterval = 0.01` | _TBD_ |
| `MembershipManager.swift` | `var isMember: Bool {` | _TBD_ |
| `MembershipManager.swift` | `var request = URLRequest(url: url)` | _TBD_ |
| `MembershipManager.swift` | `let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],` | _TBD_ |
| `MembershipManager.swift` | `let isMember = json["is_member"] as? Bool else {` | _TBD_ |
| `MusicTabViewController.swift` | `let exploreVC = LibraryViewController()` | _TBD_ |
| `MusicTabViewController.swift` | `let playlistVC = PlaylistViewController()` | _TBD_ |
| `NativeLoginViewController.swift` | `let stack = UIStackView(arrangedSubviews: [usernameField, passwordField, loginButton, guestButton, registerButton])` | _TBD_ |
| `NativeLoginViewController.swift` | `let password = passwordField.text, !password.isEmpty else {` | _TBD_ |
| `NativeLoginViewController.swift` | `let url = URL(string: "https:` | _TBD_ |
| `NativeLoginViewController.swift` | `var request = URLRequest(url: url)` | _TBD_ |
| `NativeLoginViewController.swift` | `let body: [String: String] = ["username": username, "password": password]` | _TBD_ |
| `NativeLoginViewController.swift` | `let task = URLSession.shared.dataTask(with: request) { data, response, error in` | _TBD_ |
| `NativeLoginViewController.swift` | `let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {` | _TBD_ |
| `NativeLoginViewController.swift` | `let message = json["message"] as? String ?? "Login failed"` | _TBD_ |
| `NativeLoginViewController.swift` | `let safariVC = SFSafariViewController(url: url)` | _TBD_ |
| `NativeLoginViewController.swift` | `let alert = UIAlertController(title: "Login", message: message, preferredStyle: .alert)` | _TBD_ |
| `NonceExtractor.swift` | `let webView: WKWebView` | _TBD_ |
| `NonceExtractor.swift` | `let config = WKWebViewConfiguration()` | _TBD_ |
| `NonceExtractor.swift` | `let request = URLRequest(url: url)` | _TBD_ |
| `NonceExtractor.swift` | `let js = """` | _TBD_ |
| `NonceExtractor.swift` | `let htmlJS = "document.documentElement.outerHTML.toString();"` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let config = WKWebViewConfiguration()` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let menuButton = UIBarButtonItem(title: "⋯", style: .plain, target: self, action: #selector(showUserMenu))` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let status = AuthManager.shared.isLoggedIn ? "Member: Active" : "Guest"` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let exists = FileManager.default.fileExists(atPath: pdfLocalURL().path)` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let url = pdfLocalURL()` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let preview = QLPreviewController()` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let dest = pdfLocalURL()` | _TBD_ |
| `OrderOfServiceViewController.swift` | `let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in` | _TBD_ |
| `PaddedLabel.swift` | `var textInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)` | _TBD_ |
| `PaddedLabel.swift` | `let size = super.intrinsicContentSize` | _TBD_ |
| `PlayerControlsView.swift` | `var onPlayPause: (() -> Void)?` | _TBD_ |
| `PlayerControlsView.swift` | `var onNext: (() -> Void)?` | _TBD_ |
| `PlayerControlsView.swift` | `var onPrevious: (() -> Void)?` | _TBD_ |
| `PlayerControlsView.swift` | `var onVolumeChange: ((Float) -> Void)?` | _TBD_ |
| `PlayerControlsView.swift` | `var onScrubProgress: ((Float) -> Void)?` | _TBD_ |
| `PlayerControlsView.swift` | `var onFadeOut: (() -> Void)?` | _TBD_ |
| `PlayerControlsView.swift` | `var currentVolume: Float {` | _TBD_ |
| `PlayerControlsView.swift` | `let transportStack = UIStackView(arrangedSubviews: [previousButton, playPauseButton, nextButton])` | _TBD_ |
| `PlayerControlsView.swift` | `let size = CGSize(width: width, height: height)` | _TBD_ |
| `PlayerControlsView.swift` | `let startHeight: CGFloat = 0` | _TBD_ |
| `PlayerControlsView.swift` | `let endHeight: CGFloat = height * 4` | _TBD_ |
| `PlayerControlsView.swift` | `let image = UIGraphicsGetImageFromCurrentImageContext()` | _TBD_ |
| `PlayerControlsView.swift` | `let imageName = isPlaying ? "button_pause" : "button_play"` | _TBD_ |
| `PlayerControlsView.swift` | `let currentMin = current / 60` | _TBD_ |
| `PlayerControlsView.swift` | `let currentSec = current % 60` | _TBD_ |
| `PlayerControlsView.swift` | `let durationMin = duration / 60` | _TBD_ |
| `PlayerControlsView.swift` | `let durationSec = duration % 60` | _TBD_ |
| `PlaylistViewController.swift` | `let tableView = UITableView()` | _TBD_ |
| `PlaylistViewController.swift` | `var currentTrackIndex = 0` | _TBD_ |
| `PlaylistViewController.swift` | `let cell = UITableViewCell(style: .default, reuseIdentifier: "PlaylistCell")` | _TBD_ |
| `PlaylistViewController.swift` | `let trackName = SharedPlaylistManager.shared.playlist[indexPath.row]` | _TBD_ |
| `PlaylistViewController.swift` | `let audio = AudioPlayerManager.shared` | _TBD_ |
| `PlaylistViewController.swift` | `let selectedTrack = SharedPlaylistManager.shared.playlist[indexPath.row]` | _TBD_ |
| `PlaylistViewController.swift` | `let displayName = selectedTrack.replacingOccurrences(of: "_", with: " ").capitalized` | _TBD_ |
| `PlaylistViewController.swift` | `let playlist = SharedPlaylistManager.shared.playlist` | _TBD_ |
| `PlaylistViewController.swift` | `let track = playlist[index]` | _TBD_ |
| `PlaylistViewController.swift` | `let indexPath = IndexPath(row: currentTrackIndex, section: 0)` | _TBD_ |
| `PlaylistViewController.swift` | `var playlist = SharedPlaylistManager.shared.playlist` | _TBD_ |
| `PlaylistViewController.swift` | `let movedItem = playlist.remove(at: sourceIndexPath.row)` | _TBD_ |
| `SceneDelegate.swift` | `let loginVC = NativeLoginViewController()` | _TBD_ |
| `SceneDelegate.swift` | `var window: UIWindow?` | _TBD_ |
| `SceneDelegate.swift` | `let window = UIWindow(windowScene: windowScene)` | _TBD_ |
| `SceneDelegate.swift` | `let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")` | _TBD_ |
| `SceneDelegate.swift` | `let loginVC = NativeLoginViewController()` | _TBD_ |
| `SceneDelegate.swift` | `let tabBarController = UITabBarController()` | _TBD_ |
| `SceneDelegate.swift` | `let aboutVC = ViewController()` | _TBD_ |
| `SceneDelegate.swift` | `let musicTab = UINavigationController(rootViewController: MainViewController())` | _TBD_ |
| `SceneDelegate.swift` | `let orderVC = OrderOfServiceViewController()` | _TBD_ |
| `SceneDelegate.swift` | `let biggerFont = UIFont.systemFont(ofSize: 14, weight: .bold)` | _TBD_ |
| `SceneDelegate.swift` | `let hasSeenNotice = UserDefaults.standard.bool(forKey: "hasSeenGDPRNotice")` | _TBD_ |
| `SceneDelegate.swift` | `let alert = UIAlertController(` | _TBD_ |
| `SharedPlaylistManager.swift` | `var playlist: [String] = [] {` | _TBD_ |
| `TopBarView.swift` | `let logoutButton = UIButton(type: .system)` | _TBD_ |
| `TopBarView.swift` | `let contentContainer = UIView()` | _TBD_ |
| `UIDocumentPickerViewController.swift` | `let mp3Type = UTType(filenameExtension: "mp3")!` | _TBD_ |
| `UIDocumentPickerViewController.swift` | `let picker = UIDocumentPickerViewController(forOpeningContentTypes: [mp3Type], asCopy: true)` | _TBD_ |
| `UIDocumentPickerViewController.swift` | `let fileManager = FileManager.default` | _TBD_ |
| `UIDocumentPickerViewController.swift` | `let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!` | _TBD_ |
| `UIDocumentPickerViewController.swift` | `let importedFolderURL = docsURL.appendingPathComponent("audio/imported")` | _TBD_ |
| `UIDocumentPickerViewController.swift` | `let destinationURL = importedFolderURL.appendingPathComponent(fileURL.lastPathComponent)` | _TBD_ |