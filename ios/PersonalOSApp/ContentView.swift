import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionManager()
    @State private var bootstrapping = true

    var body: some View {
        Group {
            if bootstrapping {
                ProgressView("Restoring session…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(POSTheme.background)
            } else if session.isAuthenticated {
                MainTabView()
            } else {
                LoginWebView()
            }
        }
        .environmentObject(session)
        .preferredColorScheme(.light)
        .task {
            await session.bootstrap()
            bootstrapping = false
        }
    }
}

#Preview {
    ContentView()
}
