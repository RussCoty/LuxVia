import SwiftUI

struct EulogyIntroView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("AI Eulogy Writer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("I'm here to help you compose a respectful, personal eulogy.\n\nAnswer a few questions and I'll generate a thoughtful draft you can edit, copy, or share.\n\nYour privacy matters: only what you enter is used.")
                .multilineTextAlignment(.center)
                .padding()
            
            NavigationLink("Start Writing", destination: EulogyRootView())
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("AI Eulogy Writer")
    }
}
