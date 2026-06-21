import Foundation
import UserNotifications

@MainActor
final class POSLocalNotificationScheduler {
    static let shared = POSLocalNotificationScheduler()

    private init() {}

    func syncFromServer(session: SessionManager) async {
        do {
            let plan = try await session.api.fetchLearningToday()
            await schedule(plan: plan)
        } catch {
            // Offline — keep existing scheduled notifications.
        }
    }

    func schedule(plan: POSTodayStudyPlan) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "pos.study.\(plan.date)."
        let pending = await center.pendingNotificationRequests()
        for req in pending where req.identifier.hasPrefix(prefix) {
            center.removePendingNotificationRequests(withIdentifiers: [req.identifier])
        }

        for block in plan.blocks where block.startAt > Date() {
            let content = UNMutableNotificationContent()
            content.title = block.title
            content.body = block.commuteTip ?? block.subtitle
            content.sound = .default
            content.userInfo = [
                "deep_link": "/learning",
                "block_kind": block.kind,
                "track": block.track,
            ]

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: block.startAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = prefix + block.id
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
