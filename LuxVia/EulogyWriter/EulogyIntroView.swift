// ==============================================
// File: LuxVia/EulogyWriter/EulogyIntroView.swift
// Intro screen → navigates to chat-based writer.
// iOS 15+ compatible (NavigationView fallback in Preview).
// ==============================================

import SwiftUI

public struct EulogyIntroView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Eulogy (beta)")
                        .font(.largeTitle).bold()
                    Text("A gentle, conversational way to craft a meaningful eulogy. The AI asks focused questions first, then writes when ready.")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // How it works
                VStack(alignment: .leading, spacing: 8) {
                    Text("How it works").font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        Label("You chat in your own words—no forms.", systemImage: "bubble.left.and.bubble.right")
                        Label("The AI asks 2–3 compassionate, concise questions.", systemImage: "questionmark.circle")
                        Label("When ready, it outputs a Markdown eulogy.", systemImage: "doc.plaintext")
                        Label("Nothing is saved unless you copy or share.", systemImage: "lock")
                    }
                    .labelStyle(.titleAndIcon)
                }

                // Actions
                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink {
                        EulogyWriterView.make() // ← requires EulogyWriterView.swift (below)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Start AI-guided eulogy").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    // Optional external guidance link — replace URL if you have one.
                    Link(destination: URL(string: "https://example.com/guidance")!) {
                        HStack {
                            Image(systemName: "book.closed")
                            Text("Guidance on tone and content")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                // Privacy note
                VStack(alignment: .leading, spacing: 6) {
                    Text("Privacy & Safety").font(.headline)
                    Text("Avoid sensitive identifiers you don’t want processed. Share only what you’re comfortable with.")
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)
            }
            .padding()
        }
        .navigationTitle("Eulogy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EulogyIntroView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack { EulogyIntroView() }
            } else {
                NavigationView { EulogyIntroView() }
            }
        }
    }
}
