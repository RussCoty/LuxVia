import SwiftUI

struct EulogyIntroView: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Eulogy Writer")
                    .font(.title)
                    .bold()
                Text("Hello, I'm LuxVia's AI Eulogy Writer. I can help you craft a thoughtful, personalized eulogy. Just answer a few questions and I'll generate a Markdown draft you can edit, copy, or share.")
                Text("Your privacy matters: only what you enter is used. For sensitive details, you can use a local AI provider.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            NavigationLink("Start Writing", destination: EulogyEntryPoint())
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("AI Eulogy Writer")
    }
}
