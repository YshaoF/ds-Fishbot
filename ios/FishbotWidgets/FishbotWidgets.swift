import ActivityKit
import SwiftUI
import WidgetKit

private let companionURL = URL(string: "fishbot://companion")!

struct CompanionEntry: TimelineEntry {
    let date: Date
    var message: String {
        switch Calendar.current.component(.hour, from: date) {
        case 6..<12: return "新的一天，慢慢开始。"
        case 12..<18: return "也记得给自己一点休息。"
        case 18..<23: return "今天也辛苦了。"
        default: return "夜深了，早点休息。"
        }
    }
}

struct CompanionProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompanionEntry { CompanionEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (CompanionEntry) -> Void) {
        completion(CompanionEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CompanionEntry>) -> Void) {
        let now = Date()
        let entries = (0..<12).map { CompanionEntry(date: now.addingTimeInterval(Double($0 * 3600))) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(12 * 3600))))
    }
}

struct CompanionHomeView: View {
    let entry: CompanionEntry
    @Environment(\.widgetFamily) private var family
    var content: some View {
        HStack(spacing: 16) {
            if family == .systemMedium { WhaleMark().frame(width: 100) }
            VStack(alignment: .leading, spacing: 7) {
                if family == .systemSmall { WhaleMark().frame(width: 65).padding(.bottom, 3) }
                Text("小鲸在这里").font(.headline)
                Text(entry.message).font(.caption).foregroundStyle(.secondary)
                Text("点我，回到陪伴").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .widgetURL(companionURL)
    }
    var body: some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.background, for: .widget)
        } else { content }
    }
}

struct CompanionHomeWidget: Widget {
    let kind = "FishbotCompanion"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CompanionProvider()) { entry in CompanionHomeView(entry: entry) }
            .configurationDisplayName("小鲸陪伴")
            .description("把小鲸放在主屏幕，轻点回到 Fishbot。")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CompanionActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CompanionAttributes.self) { context in
            HStack(spacing: 18) {
                WhaleMark().frame(width: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(context.attributes.name).font(.headline).lineLimit(1)
                    Text(context.isStale ? "本次陪伴已结束" : "专注陪伴 · 一次只做一件事")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if !context.isStale {
                    Text(timerInterval: context.attributes.startedAt...context.state.endsAt, countsDown: true)
                        .font(.title3.monospacedDigit()).multilineTextAlignment(.trailing).frame(maxWidth: 80)
                }
            }
            .padding(18)
            .widgetURL(companionURL)
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { WhaleMark().frame(width: 48) }
                DynamicIslandExpandedRegion(.trailing) {
                    if !context.isStale {
                        Text(timerInterval: context.attributes.startedAt...context.state.endsAt, countsDown: true)
                            .font(.title3.monospacedDigit()).frame(maxWidth: 80)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.isStale ? "本次陪伴已结束" : context.attributes.name + " · 正在陪你专注")
                        .font(.caption).lineLimit(1)
                }
            } compactLeading: { WhaleMark().frame(width: 24) }
              compactTrailing: {
                  if context.isStale { Image(systemName: "checkmark") }
                  else {
                      Text(timerInterval: context.attributes.startedAt...context.state.endsAt, countsDown: true)
                          .font(.caption2.monospacedDigit()).frame(width: 40)
                  }
              } minimal: { WhaleMark().frame(width: 23) }
              .widgetURL(companionURL)
        }
    }
}

@main
struct FishbotWidgets: WidgetBundle {
    var body: some Widget { CompanionHomeWidget(); CompanionActivityWidget() }
}
