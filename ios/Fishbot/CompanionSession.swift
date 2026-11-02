import ActivityKit
import Foundation

/// A user-started, bounded focus session. No background polling or screen capture.
@MainActor
final class CompanionSession {
    static let shared = CompanionSession()

    func status() -> [String: Any] {
        guard let activity = Activity<CompanionAttributes>.activities.first(where: {
            ($0.activityState == .active || $0.activityState == .stale) && $0.content.state.endsAt > Date()
        }) else { return ["active": false] }
        return ["active": true, "name": activity.attributes.name,
                "startedAt": activity.attributes.startedAt.timeIntervalSince1970 * 1000,
                "endsAt": activity.content.state.endsAt.timeIntervalSince1970 * 1000]
    }

    func start(name: String, minutes: Int) async throws -> [String: Any] {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LocalError.message("实时活动未开启。仍可在 App 内陪伴，或添加主屏幕小组件。")
        }
        guard [5, 25, 50].contains(minutes) else {
            throw LocalError.message("请选择5、25或50分钟。")
        }
        await stop()
        let now = Date(), end = now.addingTimeInterval(Double(minutes * 60))
        let label = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        _ = try Activity.request(
            attributes: CompanionAttributes(name: label.isEmpty ? "Fishbot" : label, startedAt: now),
            content: ActivityContent(state: CompanionAttributes.ContentState(endsAt: end), staleDate: end),
            pushType: nil)
        return status()
    }

    func stop() async {
        for activity in Activity<CompanionAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    func removeExpired() async {
        for activity in Activity<CompanionAttributes>.activities where activity.content.state.endsAt <= Date() {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
