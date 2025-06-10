import Foundation
import SwiftSoup

class LyricsSyncManager {
    static let shared = LyricsSyncManager()

    private let baseURL = "https://funeralmusic.co.uk/category/words/page/"
    private let fileName = "lyrics.json"
    private let lastSyncedKey = "lyricsLastSynced"
    private let maxPages = 20 // You can increase this if needed

    func syncLyrics(force: Bool = false, completion: @escaping (Result<[LyricEntry], Error>) -> Void) {
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
        return Date().timeIntervalSince(last) > 3600 // 1 hour
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
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                forHTTPHeaderField: "User-Agent"
            )

            URLSession.shared.dataTask(with: request) { data, _, error in
                defer { group.leave() }

                guard let data = data,
                      let html = String(data: data, encoding: .utf8) else { return }

                do {
                    let doc = try SwiftSoup.parse(html)
                    let links = try doc.select("article h2.entry-title a")
                    let urls = try links.map { try $0.attr("href") }
                    if !urls.isEmpty {
                        allURLs.append(contentsOf: urls)
                    }
                } catch {
                    // Ignore errors per page, stop on completion
                }
            }.resume()
        }

        group.notify(queue: .main) {
            if allURLs.isEmpty {
                completion(.failure(NSError(domain: "no urls found", code: 1)))
            } else {
                let uniqueURLs = Array(Set(allURLs)).sorted()
                completion(.success(uniqueURLs))
            }
        }
    }

    private func fetchLyricsEntries(from urls: [String], completion: @escaping (Result<[LyricEntry], Error>) -> Void) {
        let group = DispatchGroup()
        var entries: [LyricEntry] = []
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
                    let bodyHTML = try doc.select("div.entry-content").html()
                    let musicTag = try? doc.select("meta[name=music-filename]").attr("content")

                    let entry = LyricEntry(
                        title: title,
                        body: bodyHTML,
                        url: url,
                        musicFilename: musicTag?.isEmpty == true ? nil : musicTag
                    )
                    entries.append(entry)
                } catch {
                    errors.append(error)
                }
            }.resume()
        }

        group.notify(queue: .main) {
            if !entries.isEmpty {
                completion(.success(entries))
            } else {
                completion(.failure(errors.first ?? NSError(domain: "no entries", code: 2)))
            }
        }
    }

    private func saveToDisk(_ entries: [LyricEntry]) {
        let fileURL = getFileURL()
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save lyrics: \(error)")
        }
    }

    func loadCachedLyrics() -> [LyricEntry] {
        let fileURL = getFileURL()
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([LyricEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func getFileURL() -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(fileName)
    }
}
