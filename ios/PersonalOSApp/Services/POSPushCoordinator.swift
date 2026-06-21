import Foundation
import UserNotifications
import UIKit

@MainActor
final class POSPushCoordinator: NSObject, ObservableObject {
    static let shared = POSPushCoordinator()

    @Published private(set) var permissionGranted = false

    private override init() {
        super.init()
    }

    func bootstrapAfterLogin(session: SessionManager) async {
        await requestPermissionIfNeeded()
        UIApplication.shared.registerForRemoteNotifications()
        await POSLocalNotificationScheduler.shared.syncFromServer(session: session)
    }

    func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            permissionGranted = granted
        } else {
            permissionGranted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
    }

    func handleDeviceToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: "pos.apns.device_token")
        Task { await POSFCMRegistrar.shared.registerPendingToken() }
    }
}

extension POSPushCoordinator: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let deepLink = userInfo["deep_link"] as? String {
            NotificationCenter.default.post(name: .posOpenDeepLink, object: deepLink)
        }
    }
}

extension Notification.Name {
    static let posOpenDeepLink = Notification.Name("pos.openDeepLink")
}
