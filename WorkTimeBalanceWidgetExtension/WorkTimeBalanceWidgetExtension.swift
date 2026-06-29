import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WorkBalanceWidgetEntry {
        WorkBalanceWidgetEntry.placeholder
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> WorkBalanceWidgetEntry {
        await WorkBalanceWidgetSnapshotLoader().entry()
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<WorkBalanceWidgetEntry> {
        let entry = await WorkBalanceWidgetSnapshotLoader().entry()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

struct WorkBalanceWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WorkBalanceWidgetSnapshot

    static var placeholder: WorkBalanceWidgetEntry {
        WorkBalanceWidgetEntry(
            date: Date(),
            snapshot: WorkBalanceWidgetSnapshot(
                statusKey: "widget.status.atWork",
                monthlyBalanceText: "+0h 15m",
                averageTimeAtWorkText: "8h 45m"
            )
        )
    }
}

struct WorkBalanceWidgetSnapshot {
    let statusKey: String
    let monthlyBalanceText: String
    let averageTimeAtWorkText: String
}

struct WorkTimeBalanceWidgetExtensionEntryView: View {
    let entry: WorkBalanceWidgetEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemMedium:
            MediumWorkBalanceWidgetView(entry: entry)
        default:
            SmallWorkBalanceWidgetView(entry: entry)
        }
    }
}

private struct SmallWorkBalanceWidgetView: View {
    private static let editTodayURL = URL(string: "worktimebalance://today/edit") ?? URL(fileURLWithPath: "/")

    let entry: WorkBalanceWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(entry.snapshot.statusKey))
                .font(.title3.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            VStack(alignment: .leading, spacing: 3) {
                Text("widget.monthlyBalance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(entry.snapshot.monthlyBalanceText)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(intent: CheckInIntent()) {
                    Image(systemName: "play.fill")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button(intent: CheckOutIntent()) {
                    Image(systemName: "stop.fill")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Link(destination: Self.editTodayURL) {
                    Image(systemName: "pencil")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

private struct MediumWorkBalanceWidgetView: View {
    private static let editTodayURL = URL(string: "worktimebalance://today/edit") ?? URL(fileURLWithPath: "/")

    let entry: WorkBalanceWidgetEntry

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey(entry.snapshot.statusKey))
                    .font(.title2.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 16) {
                    metric(
                        title: "widget.monthlyBalance",
                        value: entry.snapshot.monthlyBalanceText
                    )

                    metric(
                        title: "widget.averageTimeAtWork",
                        value: entry.snapshot.averageTimeAtWorkText
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                Button(intent: CheckInIntent()) {
                    Label("widget.checkIn", systemImage: "play.fill")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button(intent: CheckOutIntent()) {
                    Label("widget.checkOut", systemImage: "stop.fill")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Link(destination: Self.editTodayURL) {
                    Label("widget.edit", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .frame(width: 132)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func metric(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkTimeBalanceWidgetExtension: Widget {
    let kind: String = WorkBalanceWidgetKind.today

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WorkTimeBalanceWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("widget.configuration.displayName")
        .description("widget.configuration.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@MainActor
private struct WorkBalanceWidgetSnapshotLoader {
    private let calendar = Calendar.current
    private let settingsStore = AppSettingsStore()
    private let statisticsCalculator = StatisticsCalculator()

    func entry(date: Date = Date()) -> WorkBalanceWidgetEntry {
        WorkBalanceWidgetEntry(date: date, snapshot: snapshot(for: date))
    }

    private func snapshot(for date: Date) -> WorkBalanceWidgetSnapshot {
        do {
            let container = try WorkBalanceModelContainerFactory.makeSharedModelContainer()
            let modelContext = ModelContext(container)
            let repository = WorkDayRepository(modelContext: modelContext, calendar: calendar)
            let workDay = try repository.workDay(for: date)
            let workDays = try currentMonthWorkDays(for: date, repository: repository)

            return WorkBalanceWidgetSnapshot(
                statusKey: statusKey(for: workDay),
                monthlyBalanceText: formattedSignedDuration(statisticsCalculator.accumulatedBalance(
                    for: workDays,
                    standardDuration: settingsStore.standardWorkdayDuration
                )),
                averageTimeAtWorkText: formattedDuration(statisticsCalculator.averageTimeAtWork(for: workDays))
            )
        } catch {
            return WorkBalanceWidgetSnapshot(
                statusKey: "widget.status.checkIn",
                monthlyBalanceText: formattedSignedDuration(0),
                averageTimeAtWorkText: formattedDuration(0)
            )
        }
    }

    private func currentMonthWorkDays(for date: Date, repository: WorkDayRepository) throws -> [WorkDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        return try repository.workDays(from: monthInterval.start, to: monthInterval.end)
    }

    private func statusKey(for workDay: WorkDay?) -> String {
        if workDay?.checkOut != nil {
            return "widget.status.leftWork"
        }

        if workDay?.checkIn != nil {
            return "widget.status.atWork"
        }

        return "widget.status.checkIn"
    }

    private func formattedSignedDuration(_ duration: TimeInterval) -> String {
        let sign: String
        if duration > 0 {
            sign = "+"
        } else if duration < 0 {
            sign = "-"
        } else {
            sign = ""
        }

        return sign + formattedDuration(abs(duration))
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .pad

        var formatterCalendar = Calendar.current
        formatterCalendar.locale = settingsStore.appLanguage.locale ?? .current
        formatter.calendar = formatterCalendar

        return formatter.string(from: max(0, duration)) ?? ""
    }
}

#Preview(as: .systemSmall) {
    WorkTimeBalanceWidgetExtension()
} timeline: {
    WorkBalanceWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    WorkTimeBalanceWidgetExtension()
} timeline: {
    WorkBalanceWidgetEntry.placeholder
}
