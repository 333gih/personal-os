import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

/// Push transport coordinator.
///
/// Default path is Firebase Cloud Messaging (parity with fash-ios): the raw APNs device token is fed to
/// `Messaging.setAPNSToken`, Firebase mints an FCM registration token, and that token is registered with
/// `fash-auth` (`api/v1/auth/fcm/register`) — the same backend both apps deliver through.
///
/// Fallback path (Info.plist `USE_FIREBASE_MESSAGING = false`, or GoogleService-Info.plist missing) keeps the
/// legacy pure-APNs behavior: the hex-encoded APNs device token is registered directly with the backend.
@MainActor
final class POSPushCoordinator: NSObject, ObservableObject {
    static let shared = POSPushCoordinator()

    @Published private(set) var permissionGranted = false

    private override init() {
        super.init()
    }

    // MARK: - Feature flag / configuration

    /// True when a Firebase config plist is bundled (CI decodes the secret before archive).
    static var isFirebaseConfigured: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    /// Effective transport: Firebase FCM only when the flag is on AND the plist is present.
    static var usesFirebaseMessaging: Bool {
        PersonalOSAppConfig.useFirebaseMessaging && isFirebaseConfigured
    }

    /// Call once from `didFinishLaunchingWithOptions`.
    static func configureMessagingIfNeeded() {
        UNUserNotificationCenter.current().delegate = POSPushCoordinator.shared
        guard usesFirebaseMessaging else {
            if PersonalOSAppConfig.useFirebaseMessaging && !isFirebaseConfigured {
                NSLog("[POSPush] GoogleService-Info.plist missing — FCM disabled, using pure APNs registration")
            } else {
                NSLog("[POSPush] USE_FIREBASE_MESSAGING=false — using pure APNs registration")
            }
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Messaging.messaging().delegate = POSPushCoordinator.shared
        NSLog("[POSPush] Firebase FCM configured")
    }

    /// Maps the build config to the APNs token type Firebase must use to resolve the FCM token.
    private static func apnsTokenTypeForCurrentBuild() -> MessagingAPNSTokenType {
        #if DEBUG
        return .sandbox
        #else
        return .prod
        #endif
    }

    // MARK: - Lifecycle

    func bootstrapAfterLogin(session: SessionManager) async {
        await requestPermissionIfNeeded()
        UIApplication.shared.registerForRemoteNotifications()
        if Self.usesFirebaseMessaging {
            await registerCurrentFCMTokenIfSession()
        } else {
            await POSFCMRegistrar.shared.registerPendingToken()
        }
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

    // MARK: - APNs device token

    func applyAPNSDeviceToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: "pos.apns.device_token")

        guard Self.usesFirebaseMessaging else {
            // Pure-APNs fallback: register the raw device token directly.
            Task { await POSFCMRegistrar.shared.registerPendingToken() }
            return
        }

        Messaging.messaging().setAPNSToken(deviceToken, type: Self.apnsTokenTypeForCurrentBuild())
        Task { await registerCurrentFCMTokenIfSession() }
    }

    /// Retained for API compatibility (previous pure-APNs entry point).
    func handleDeviceToken(_ deviceToken: Data) {
        applyAPNSDeviceToken(deviceToken)
    }

    // MARK: - FCM token

    private func registerCurrentFCMTokenIfSession() async {
        guard Self.usesFirebaseMessaging else { return }
        for attempt in 0 ..< 10 {
            if Messaging.messaging().apnsToken == nil {
                try? await Task.sleep(nanoseconds: 500_000_000)
                continue
            }
            if let token = await Self.fetchFCMToken(), !token.isEmpty {
                await POSFCMRegistrar.shared.register(token: token)
                return
            }
            if attempt < 9 {
                try? await Task.sleep(nanoseconds: UInt64(500_000_000) * UInt64(min(attempt + 1, 4)))
            }
        }
        NSLog("[POSPush] FCM token unavailable after retries — check APNs key on Firebase, GoogleService-Info BUNDLE_ID, and Push capability")
    }

    private static func fetchFCMToken() async -> String? {
        await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error {
                    NSLog("[POSPush] FCM token fetch failed: \(error.localizedDescription)")
                }
                continuation.resume(returning: token)
            }
        }
    }

    func appDidReceiveRemoteMessage(_ userInfo: [AnyHashable: Any]) {
        guard Self.usesFirebaseMessaging else { return }
        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
}

// MARK: - MessagingDelegate (FCM token refresh)

extension POSPushCoordinator: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        Task { @MainActor in
            await POSFCMRegistrar.shared.register(token: fcmToken)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension POSPushCoordinator: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list, .badge]
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
