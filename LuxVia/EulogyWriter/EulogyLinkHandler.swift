// =======================================================
// File: LuxVia/Support/EulogyLinkHandler.swift
// Intercepts luxvia://eulogy and presents the writer as a sheet.
// Call `.eulogyLinkHandler()` on your Words tab root view.
// =======================================================
import SwiftUI

private struct EulogyLinkHandlerModifier: ViewModifier {
    @State private var showEulogy = false

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                // Change scheme/host/path to match your existing link if needed.
                if url.scheme == "luxvia", url.host == "eulogy" || url.path == "/eulogy" {
                    showEulogy = true
                }
            }
            .sheet(isPresented: $showEulogy) {
                // Wrap in NavigationView for iOS 15 support
                if #available(iOS 16.0, *) {
                    NavigationStack { EulogyWriterView.make() }
                } else {
                    NavigationView { EulogyWriterView.make() }
                }
            }
    }
}

extension View {
    /// Attach to any container that should respond to `luxvia://eulogy`.
    func eulogyLinkHandler() -> some View {
        modifier(EulogyLinkHandlerModifier())
    }
}

// =======================================================
// INTEGRATION (example):
// Wherever your "Words" tab custom section root view is defined,
// wrap it with `.eulogyLinkHandler()` so your existing link works.
//
// Example:
// struct WordsTabRootView: View {
//     var body: some View {
//         WordsContent()  // <-- your existing view
//             .eulogyLinkHandler() // enables luxvia://eulogy deep link
//     }
// }
//
// Ensure your link/button in the custom section uses:
// Link("AI Eulogy (beta)", destination: URL(string: "luxvia://eulogy")!)
// or programmatically: openURL(URL(string: "luxvia://eulogy")!)
// =======================================================
