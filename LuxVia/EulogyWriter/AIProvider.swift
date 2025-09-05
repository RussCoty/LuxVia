// LuxVia – AI Eulogy Writer (POC using OpenAI, swappable to local LLM)
// File: AIProvider.swift

import Foundation

// MARK: - EulogyInput
struct EulogyInput {
    var name: String
    var age: Int?
    var relationship: String
    var pronouns: String?
    var traits: [String]
    var anecdotes: [String]
    var achievements: [String]
    var religiousNotes: String?
    var audience: String?
    var tone: String
    var length: String
    var includeQuotes: Bool
    var readingPersona: String?
}

// MARK: - AIProvider Abstraction
protocol AIProvider {
    func generateEulogy(input: EulogyInput, cancelToken: CancellationToken) async throws -> String
}

// MARK: - CancellationToken
final class CancellationToken {
    private var isCancelled = false
    func cancel() { isCancelled = true }
    func checkCancelled() throws {
        if isCancelled { throw CancellationError() }
    }
}

struct CancellationError: Error {}

// MARK: - Prompt Builder
struct EulogyPromptBuilder {
    static func buildMessages(input: EulogyInput) -> [[String: String]] {
        let system = "You are an expert eulogy writer. Strictly follow the provided structure, tone, and facts. Do not invent details. Output in Markdown."
        var user = "Write a eulogy for \(input.name)"
        if let age = input.age { user += ", age \(age)" }
        user += ". Relationship: \(input.relationship)."
        if let pronouns = input.pronouns { user += " Pronouns: \(pronouns)." }
        if !input.traits.isEmpty { user += " Traits: \(input.traits.joined(separator: ", "))." }
        if !input.anecdotes.isEmpty { user += " Anecdotes: \(input.anecdotes.joined(separator: ", "))." }
        if !input.achievements.isEmpty { user += " Achievements: \(input.achievements.joined(separator: ", "))." }
        if let notes = input.religiousNotes { user += " Religious notes: \(notes)." }
        if let audience = input.audience { user += " Audience: \(audience)." }
        user += " Tone: \(input.tone). Length: \(input.length)."
        user += input.includeQuotes ? " Include quotes." : ""
        if let persona = input.readingPersona { user += " Reading persona: \(persona)." }
        user += "\nStrict guidance: Do not invent details. Use only provided facts. Output in Markdown."
        return [
            ["role": "system", "content": system],
            ["role": "user", "content": user]
        ]
    }
}

// MARK: - OpenAIChatProvider (POC)
final class OpenAIChatProvider: AIProvider {
    var baseURL: URL
    var model: String
    var temperature: Double
    var apiKey: String
    private var session: URLSession
    
    init(baseURL: URL = URL(string: "https://api.openai.com/v1")!,
         model: String = "gpt-4o-mini",
         temperature: Double = 0.7,
         apiKey: String) {
        self.baseURL = baseURL
        self.model = model
        self.temperature = temperature
        self.apiKey = apiKey
        self.session = URLSession(configuration: .default)
    }
    
    func generateEulogy(input: EulogyInput, cancelToken: CancellationToken) async throws -> String {
        let messages = EulogyPromptBuilder.buildMessages(input: input)
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": temperature
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request) // PATCHED
        cancelToken.checkCancelled()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let content = choices?.first?["message"] as? [String: Any]
        return content?["content"] as? String ?? ""
    }
}

// MARK: - Secrets (dev only)
struct Secrets {
    static func openAIAPIKey() -> String? {
        if let key = UserDefaults.standard.string(forKey: "OPENAI_API_KEY") {
            return key
        }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
}

// MARK: - EulogyViewModel
import Combine
import SwiftUI

@MainActor
final class EulogyViewModel: ObservableObject {
    @Published var input = EulogyInput(
        name: "",
        age: nil,
        relationship: "",
        pronouns: nil,
        traits: [],
        anecdotes: [],
        achievements: [],
        religiousNotes: nil,
        audience: nil,
        tone: "Respectful",
        length: "Medium",
        includeQuotes: false,
        readingPersona: nil
    )
    @Published var outputMarkdown: String = ""
    @Published var isLoading = false
    @Published var error: String?
    private(set) var provider: AIProvider
    private var cancelToken: CancellationToken?
    
    init(provider: AIProvider) {
        self.provider = provider
    }
    
    func generate() {
        self.isLoading = true
        self.error = nil
        self.outputMarkdown = ""
        let token = CancellationToken()
        self.cancelToken = token
        Task {
            do {
                let result = try await self.provider.generateEulogy(input: self.input, cancelToken: token)
                self.outputMarkdown = result
            } catch is CancellationError {
                self.error = "Cancelled."
            } catch {
                self.error = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    func cancel() {
        self.cancelToken?.cancel()
    }
}

// MARK: - EulogyWriterView (SwiftUI)
import MarkdownUI

struct EulogyWriterView: View {
    @StateObject var viewModel: EulogyViewModel
    @State private var apiKey: String = Secrets.openAIAPIKey() ?? ""
    
    var body: some View {
        Form {
            Section("Eulogy Details") { // PATCHED
                TextField("Name", text: $viewModel.input.name)
                TextField("Age", value: $viewModel.input.age, formatter: NumberFormatter())
                TextField("Relationship", text: $viewModel.input.relationship)
                TextField("Pronouns", text: $viewModel.input.pronouns.toNonOptional())
                TextField("Traits (comma separated)", text: Binding(
                    get: { viewModel.input.traits.joined(separator: ", ") },
                    set: { viewModel.input.traits = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                TextField("Anecdotes (comma separated)", text: Binding(
                    get: { viewModel.input.anecdotes.joined(separator: ", ") },
                    set: { viewModel.input.anecdotes = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                TextField("Achievements (comma separated)", text: Binding(
                    get: { viewModel.input.achievements.joined(separator: ", ") },
                    set: { viewModel.input.achievements = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                TextField("Religious Notes", text: Binding($viewModel.input.religiousNotes, ""))
                TextField("Audience", text: Binding($viewModel.input.audience, ""))
                TextField("Tone", text: $viewModel.input.tone)
                TextField("Length", text: $viewModel.input.length)
                Toggle("Include Quotes", isOn: $viewModel.input.includeQuotes)
                TextField("Reading Persona", text: Binding($viewModel.input.readingPersona, ""))
            }
            Section(header: Text("Provider (POC)")) {
                TextField("OpenAI API Key", text: $apiKey)
                Button("Save API Key") {
                    UserDefaults.standard.set(apiKey, forKey: "OPENAI_API_KEY")
                }
            }
            Section {
                Button(viewModel.isLoading ? "Generating..." : "Generate") {
                    if !apiKey.isEmpty {
                        viewModel.cancel()
                        viewModel.outputMarkdown = ""
                        viewModel.error = nil
                        viewModel.isLoading = true
                        let provider = OpenAIChatProvider(apiKey: apiKey)
                        viewModel.input = viewModel.input // force update
                        viewModel.outputMarkdown = ""
                        viewModel.error = nil
                        viewModel.isLoading = true
                        viewModel.cancelToken = nil
                        viewModel.provider = provider
                        viewModel.generate()
                    }
                }.disabled(viewModel.isLoading || apiKey.isEmpty)
                if viewModel.isLoading {
                    Button("Cancel") { viewModel.cancel() }
                }
            }
            if let error = viewModel.error {
                Text(error).foregroundColor(.red)
            }
            if !viewModel.outputMarkdown.isEmpty {
                Markdown(viewModel.outputMarkdown)
                Button("Copy") {
                    UIPasteboard.general.string = viewModel.outputMarkdown
                }
                .buttonStyle(.bordered)
                Button("Share") {
                    let activityVC = UIActivityViewController(activityItems: [viewModel.outputMarkdown], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("AI Eulogy Writer")
    }
}

// MARK: - Entry Point
struct EulogyEntryPoint: View {
    var body: some View {
        NavigationView {
            EulogyWriterView(viewModel: EulogyViewModel(provider: OpenAIChatProvider(apiKey: Secrets.openAIAPIKey() ?? "")))
        }
    }
}

// MARK: - Helpers
extension Binding where Value == String? {
    func toNonOptional(default defaultValue: String = "") -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
