import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Time Manager AI")
                .font(.largeTitle)
                .padding()

            Text("App loaded successfully!")
                .font(.title2)
                .foregroundColor(.green)
                .padding()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}