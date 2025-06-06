import Foundation
import SwiftSoup

struct LyricEntry: Codable {
    let title: String
    let body: String  // now stores raw HTML
    let url: String
}

class LyricsSyncManager {
    static let shared = LyricsSyncManager()
    
    private let baseURL = "https://funeralmusic.co.uk/category/words/"
    private let fileName = "lyrics.json"

    func syncLyrics(completion: @escaping (Result<[LyricEntry], Error>) -> Void) {
        fetchPostURLs(from: baseURL) { result in
            switch result {
            case .success(let urls):
                self.fetchLyricsEntries(from: urls) { lyricsResult in
                    switch lyricsResult {
                    case .success(let entries):
                        self.saveToDisk(entries)
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

    private func fetchPostURLs(from categoryURL: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: categoryURL) else {
            return completion(.failure(NSError(domain: "bad url", code: 1)))
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let html = String(data: data, encoding: .utf8) else {
                return completion(.failure(error ?? NSError(domain: "failed html fetch", code: 2)))
            }

            do {
                let doc = try SwiftSoup.parse(html)
                let links = try doc.select("article h2.entry-title a")
                let urls = try links.map { try $0.attr("href") }
                completion(.success(urls))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func fetchLyricsEntries(from urls: [String], completion: @escaping (Result<[LyricEntry], Error>) -> Void) {
        let group = DispatchGroup()
        var entries: [LyricEntry] = []
        var errors: [Error] = []

        for url in urls {
            guard let urlObj = URL(string: url) else { continue }
            group.enter()

            var request = URLRequest(url: urlObj)
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
                forHTTPHeaderField: "User-Agent"
            )

            URLSession.shared.dataTask(with: request) { data, _, error in
                defer { group.leave() }

                guard let data = data, error == nil,
                      let html = String(data: data, encoding: .utf8) else {
                    if let err = error { errors.append(err) }
                    return
                }

                do {
                    let doc = try SwiftSoup.parse(html)
                    let title = try doc.select("h1.entry-title").text()
                    let bodyHTML = try doc.select("div.entry-content").html()
                    let entry = LyricEntry(title: title, body: bodyHTML, url: url)
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
                completion(.failure(errors.first ?? NSError(domain: "no entries", code: 3)))
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
