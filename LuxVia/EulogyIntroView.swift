import SwiftUI
import MarkdownUI

struct EulogyIntroView: View {
    var body: some View {
        VStack(spacing: 24) {
            Markdown("""
# AI Eulogy Writer

Hello, I'm LuxVia's AI Eulogy Writer. I can help you craft a thoughtful, personalized eulogy. Just answer a few questions and I'll generate a Markdown draft you can edit, copy, or share.

Your privacy matters: only what you enter is used. For sensitive details, you can use a local AI provider.
""")
            NavigationLink("Start Writing", destination: EulogyWriterView.make())
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("AI Eulogy Writer")
    }
}
