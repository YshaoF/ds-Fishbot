import ActivityKit
import Foundation

struct CompanionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
    }
    var name: String
    var startedAt: Date
}
