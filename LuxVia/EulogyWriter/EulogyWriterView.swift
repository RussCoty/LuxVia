// ==============================================
// File: LuxVia/EulogyWriter/EulogyWriterView.swift
// AI Eulogy Writer using local ML model and template generation
// ==============================================

import SwiftUI
import UIKit

struct EulogyWriterView: View {
    @StateObject private var engine = EulogyChatEngine()
    @State private var input = ""
    @State private var isSending = false
    @State private var showShareSheet = false
    @State private var shareText = ""

    static func make() -> some View { EulogyWriterView() }

    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(engine.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if engine.isThinking {
                            TypingBubble()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                }
                .onChange(of: engine.messages) { _ in
                    if let last = engine.messages.last { 
                        withAnimation { 
                            proxy.scrollTo(last.id, anchor: .bottom) 
                        } 
                    }
                }
            }
            
            inputBar
            
            HStack(spacing: 12) {
                Button("Restart") { 
                    engine.start() 
                }
                .buttonStyle(.bordered)
                
                Button("Copy All") { 
                    copyTranscript() 
                }
                .buttonStyle(.bordered)
                
                if #available(iOS 16.0, *) {
                    ShareLink("Share", item: transcript())
                        .buttonStyle(.bordered)
                } else {
                    Button("Share") { 
                        shareText = transcript()
                        showShareSheet = true 
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Eulogy (beta)")
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [shareText])
        }
    }
    
    private var header: some View {
        HStack {
            Circle().fill(Color.green.opacity(0.85)).frame(width: 8, height: 8)
            Text("LuxVia • Eulogy Assistant").font(.headline)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                TextEditor(text: $input)
                    .padding(8)
                    .frame(minHeight: 40, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .disableAutocorrection(false)
                    .textInputAutocapitalization(.sentences)
            }
            .frame(minHeight: 40, maxHeight: 120)

            Button {
                send()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.all, 12)
        .background(.thinMaterial)
    }
    
    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        isSending = true
        engine.send(text)
        DispatchQueue.main.async { isSending = false }
    }
    
    private func transcript() -> String {
        engine.messages
            .map { ($0.role == .user ? "You" : "Assistant") + ": " + $0.text }
            .joined(separator: "\n\n")
    }
    
    private func copyTranscript() {
        UIPasteboard.general.string = transcript()
    }
}

// MARK: - Supporting Views

private struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user { Spacer() }
            VStack(alignment: .leading, spacing: 6) {
                if message.role == .draft {
                    Text("Draft eulogy").font(.caption).foregroundColor(.secondary)
                }
                Text(message.text)
                    .font(message.role == .draft ? .body : .callout)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(message.role == .user ? Color.accentColor : Color(.secondarySystemBackground))
                    )
            }
            if message.role != .user { Spacer() }
        }
    }
}

private struct TypingBubble: View {
    var body: some View {
        HStack {
            ProgressView().scaleEffect(0.8)
            Text("Thinking…").foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

