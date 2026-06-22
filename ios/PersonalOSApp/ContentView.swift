import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionManager()
    @State private var bootstrapping = true
    @Environment(\.scenePhase) private var scenePhase

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
            POSPushSessionBridge.shared.session = session
            await session.bootstrap()
            if session.isAuthenticated {
                await POSPushCoordinator.shared.bootstrapAfterLogin(session: session)
            }
            bootstrapping = false
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, !bootstrapping else { return }
            Task {
                await session.refreshSessionIfNeeded(force: false)
                if session.isAuthenticated {
                    session.scheduleProactiveRefresh()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
