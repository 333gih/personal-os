import UIKit

/// Firebase + APNs lifecycle. `FirebaseAppDelegateProxyEnabled` is NO in Info.plist — all FCM/APNs hooks are wired here.
/// Transport (FCM vs pure APNs) is decided at runtime by `POSPushCoordinator` via the `USE_FIREBASE_MESSAGING` flag.
final class POSAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        POSPushCoordinator.configureMessagingIfNeeded()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            POSPushCoordinator.shared.applyAPNSDeviceToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Simulator or missing push capability — local notifications still work.
        NSLog("[POSPush] APNs registration failed: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            POSPushCoordinator.shared.appDidReceiveRemoteMessage(userInfo)
            completionHandler(.newData)
        }
    }
}
