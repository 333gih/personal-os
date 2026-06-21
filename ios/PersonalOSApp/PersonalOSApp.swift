import SwiftUI

@main
struct PersonalOSApp: App {
    @UIApplicationDelegateAdaptor(POSAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
