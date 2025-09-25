// ==============================================
// File: LuxVia/EulogyWriter/EulogyWriterView.swift
// Chat-only “AI Eulogy” option. Uses types from AIProvider.swift.
// Requires: ChatMessage, ChatProvider, CancellationToken, OpenAIChatProvider, Secrets.
// ==============================================

import SwiftUI
import UIKit

struct EulogyWriterView: View {
    @StateObject private var vm = EulogyChatViewModel()
    @State private var apiKey: String = Secrets.openAIAPIKey() ?? ""
    @State private var showShare = false

    static func make() -> some View { EulogyWriterView() }

    var body: some View {
        VStack(spacing: 0) {
            // Top controls (feature-local)
            HStack(spacing: 8) {
                SecureField("OpenAI API Key", text: $apiKey)
                    .textContentType(.password)
                    .font(.callout)
                Button("Use Key") {
                    UserDefaults.standard.set(apiKey, forKey: "OPENAI_API_KEY")
                    vm.configure(apiKey: apiKey) // keep encapsulated
                }
                .disabled(apiKey.isEmpty)
                .buttonStyle(.bordered)
                Button("Restart") { vm.start() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { msg in
                            ChatBubble(message: msg).id(msg.id)
                        }
                        if vm.isLoading { ProgressView().padding(.horizontal) }
                    }
                    .padding(.vertical, 10)
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            Divider()

            // Input bar
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type your message…", text: $vm.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button(vm.isLoading ? "Sending…" : "Send") { vm.send() }
                    .disabled(vm.isLoading || apiKey.isEmpty)
                    .buttonStyle(.borderedProminent)
                if vm.isLoading {
                    Button("Cancel") { vm.cancel() }
                        .buttonStyle(.bordered)
                }
            }
            .padding()

            // Tools
            HStack {
                Button("Copy Transcript") { UIPasteboard.general.string = vm.transcript() }
                    .buttonStyle(.bordered)
                if #available(iOS 16.0, *) {
                    ShareLink("Share", item: vm.transcript()).buttonStyle(.bordered)
                } else {
                    Button("Share") { showShare = true }.buttonStyle(.bordered)
                }
            }
            .padding(.bottom, 8)
            .sheet(isPresented: $showShare) { ActivityView(activityItems: [vm.transcript()]) }

            if let error = vm.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.bottom, 6)
            }
        }
        .navigationTitle("AI Eulogy (beta)")
        .onAppear {
            if !apiKey.isEmpty { vm.configure(apiKey: apiKey) }
            if vm.messages.isEmpty { vm.start() }
        }
    }
}

// MARK: - ViewModel (uses ChatProvider from AIProvider.swift)
@MainActor
final class EulogyChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var error: String?

    private var provider: ChatProvider?
    private var cancelToken: CancellationToken?

    private let systemPrompt = """
    You are an expert eulogy writer guiding a gentle interview.
    1) Start with 2–3 compassionate, concise questions.
    2) Ask only what’s needed, one message at a time.
    3) Never invent details. If unsure, ask.
    4) When ready, say “I’m ready to write.” Then in the NEXT message, output the full eulogy in Markdown.
    5) Structure: opening, character, stories, gratitude, farewell. Respect cultural/religious notes. Avoid clichés.
    """

    func configure(apiKey: String) {
        provider = OpenAIChatProvider(apiKey: apiKey)
        if messages.isEmpty { start() }
    }

    func start() {
        messages = [
            .init(role: .system, content: systemPrompt),
            .init(role: .assistant, content: "I’m so sorry for your loss. Could you share their name and how you’re connected? Is there one memory you’d like everyone to remember?")
        ]
        error = nil
    }

    func send() {
        guard let provider else { error = "Set API key first."; return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(.init(role: .user, content: text))
        inputText = ""
        isLoading = true
        error = nil
        let token = CancellationToken()
        cancelToken = token

        Task {
            defer { isLoading = false }
            do {
                let reply = try await provider.complete(messages: messages, cancelToken: token)
                messages.append(.init(role: .assistant, content: reply))
            } catch is CancellationError {
                error = "Cancelled."
            } catch {
                error = error.localizedDescription
            }
        }
    }

    func cancel() {
        cancelToken?.cancel()
        cancelToken = nil
    }

    func transcript() -> String {
        messages
            .filter { $0.role != .system }
            .map { ($0.role == .user ? "You" : "AI") + ": " + $0.content }
            .joined(separator: "\n\n")
    }
}

// MARK: - UI bits
private struct ChatBubble: View {
    let message: ChatMessage
    var isUser: Bool { message.role == .user }
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                if message.role == .assistant, let attr = try? AttributedString(markdown: message.content) {
                    Text(attr).textSelection(.enabled)
                } else {
                    Text(message.content).textSelection(.enabled)
                }
            }
            .padding(10)
            .background(isUser ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

