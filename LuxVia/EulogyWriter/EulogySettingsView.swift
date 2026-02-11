import SwiftUI

struct EulogySettingsView: View {
    @StateObject private var settings = EulogySettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Enable AI Responses", isOn: $settings.useAIResponses)
                } header: {
                    Text("Conversation Style")
                } footer: {
                    Text("When enabled, the assistant will generate natural, context-aware responses. When disabled, it uses pre-written templates. AI responses run 100% locally on your device.")
                }
                
                Section {
                    Text("Phase 1: Infrastructure")
                        .font(.headline)
                    Text("AI response generation is currently a placeholder. Full Llama 3.2 3B integration coming in Phase 2.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Eulogy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
