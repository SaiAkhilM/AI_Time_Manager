import SwiftUI

struct TutorialTriggerView: View {
    @AppStorage("showTutorial") private var showTutorial: Bool = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var showingTutorial: Bool = false

    var body: some View {
        EmptyView()
            .onAppear {
                if !hasSeenTutorial && showTutorial {
                    showingTutorial = true
                }
            }
            .sheet(isPresented: $showingTutorial) {
                TutorialView()
                    .onDisappear {
                        hasSeenTutorial = true
                        showTutorial = false
                    }
            }
    }
}

#Preview {
    TutorialTriggerView()
}