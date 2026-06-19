import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionManager()

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
            } else {
                LoginWebView()
            }
        }
        .environmentObject(session)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
