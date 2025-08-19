import Foundation
import SwiftSoup

final class LyricsSyncManager {
    static let shared = LyricsSyncManager()

    private let baseURL = "https://funeralmusic.co.uk/category/words/page/"
    private let fileName = "lyrics.json"
    private let lastSyncedKey = "lyricsLastSynced"
    private let maxPages = 20

    func syncLyrics(force: Bool = false, completion: @escaping (Result<[Lyric], Error>) -> Void) {
        if !force && !shouldSync() {
            let cached = loadCachedLyrics()
            completion(.success(cached))
            return
        }

        fetchAllPostURLs { result in
            switch result {
            case .success(let urls):
                self.fetchLyricsEntries(from: urls) { lyricsResult in
                    switch lyricsResult {
                    case .success(let entries):
                        self.saveToDisk(entries)
                        self.updateLastSynced()
                        completion(.success(entries))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func shouldSync() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastSyncedKey) as? Date else { return true }
        return Date().timeIntervalSince(last) > 3600
    }

    private func updateLastSynced() {
        UserDefaults.standard.set(Date(), forKey: lastSyncedKey)
    }

    private func fetchAllPostURLs(completion: @escaping (Result<[String], Error>) -> Void) {
        var allURLs: [String] = []
        let group = DispatchGroup()

        for page in 1...maxPages {
            let pageURL = "\(baseURL)\(page)/"
            guard let url = URL(string: pageURL) else { continue }

            group.enter()
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

            URLSession.shared.dataTask(with: request) { data, _, error in
                defer { group.leave() }
                guard let data = data,
                      let html = String(data: data, encoding: .utf8) else { return }

                do {
                    let doc = try SwiftSoup.parse(html)
                    let links = try doc.select("article h2.entry-title a")
                    let urls = try links.map { try $0.attr("href") }
                    allURLs.append(contentsOf: urls)
                } catch { /* ignore */ }
            }.resume()
        }

        group.notify(queue: .main) {
            let uniqueURLs = Array(Set(allURLs)).sorted()
            uniqueURLs.isEmpty
                ? completion(.failure(NSError(domain: "no urls found", code: 1)))
                : completion(.success(uniqueURLs))
        }
    }

    private func fetchLyricsEntries(from urls: [String], completion: @escaping (Result<[Lyric], Error>) -> Void) {
        let group = DispatchGroup()
        var entries: [Lyric] = []
        var errors: [Error] = []

        for url in urls {
            guard let urlObj = URL(string: url) else { continue }
            group.enter()

            URLSession.shared.dataTask(with: urlObj) { data, _, error in
                defer { group.leave() }
                guard let data = data,
                      let html = String(data: data, encoding: .utf8) else {
                    if let err = error { errors.append(err) }
                    return
                }

                do {
                    let doc = try SwiftSoup.parse(html)
                    let title = try doc.select("h1.entry-title").text()
                    let content = try doc.select("div.entry-content").html()
                    let musicTag = try? doc.select("meta[name=music-filename]").attr("content")

                    let lyric = Lyric(
                        title: title,
                        body: content,
                        type: .lyric,
                        audioFileName: (musicTag?.isEmpty == true ? nil : musicTag),
                        category: nil
                    )

                    entries.append(lyric)
                } catch {
                    errors.append(error)
                }

            }.resume()
        }

        group.notify(queue: .main) {
            !entries.isEmpty
                ? completion(.success(entries))
                : completion(.failure(errors.first ?? NSError(domain: "no entries", code: 2)))
        }
    }

    private func saveToDisk(_ entries: [Lyric]) {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: getFileURL(), options: .atomic)
        } catch {
            print("Failed to save lyrics: \(error)")
        }
    }

    func loadCachedLyrics() -> [Lyric] {
        guard let data = try? Data(contentsOf: getFileURL()),
              let entries = try? JSONDecoder().decode([Lyric].self, from: data) else {
            return []
        }
        return entries
    }

    private func getFileURL() -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(fileName)
    }
}
