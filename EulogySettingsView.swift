// EulogySettingsView.swift
// Presents settings to toggle between Llama AI responses and template fallback.

import SwiftUI

// Assumes there is a singleton settings model `EulogySettings` with a
// `shared` static instance and a `useAIResponses: Bool` property published.
// This view binds to that property and allows users to toggle AI on/off.

struct EulogySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = EulogySettings.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Responses"), footer: Text("Turn this on to use the local Llama model for AI-generated questions and guidance. Turn off to use reliable, pre-written templates.")) {
                    Toggle(isOn: $settings.useAIResponses) {
                        Label("Use AI (Llama)", systemImage: settings.useAIResponses ? "sparkles" : "text.bubble"
                        )
                    }
                    .tint(.accentColor)
                }
            }
            .navigationTitle("Eulogy Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EulogySettingsView()
}
