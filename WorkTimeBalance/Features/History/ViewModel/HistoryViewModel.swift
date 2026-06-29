import Foundation
import Observation
import SwiftData

struct HistoryWorkDayRow: Identifiable, Hashable {
    let id: PersistentIdentifier
    let day: Date
    let dateText: String
    let checkInText: String?
    let checkOutText: String?
    let workedTimeText: String
    let dailyBalanceText: String?
}

@MainActor
@Observable
final class HistoryViewModel {
    var monthTitle = ""
    var totalWorkedTimeText = ""
    var averageTimeAtWorkText = ""
    var monthlyBalanceText = ""
    var rows: [HistoryWorkDayRow] = []
    var isEditingWorkDay = false
    var canEditDate = false
    var editorTitle = ""
    var draftDate = Date()
    var draftCheckIn = Date()
    var draftCheckOut = Date()
    var draftLunchBreakMinutes = Int(WorkBalanceDefaults.defaultLunchBreakDuration / 60)
    var lastPersistenceError: Error?

    var draftLunchBreakText: String {
        formattedDuration(TimeInterval(max(0, draftLunchBreakMinutes) * 60))
    }

    private let calendar: Calendar
    private let dateProvider: () -> Date
    private let workTimeCalculator: WorkTimeCalculator
    private let statisticsCalculator: StatisticsCalculator
    private let settingsStore: AppSettingsStore
    private let durationFormatter: DateComponentsFormatter
    private let monthFormatter: DateFormatter
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter

    init(
        calendar: Calendar = .current,
        dateProvider: @escaping () -> Date = Date.init,
        workTimeCalculator: WorkTimeCalculator? = nil,
        statisticsCalculator: StatisticsCalculator? = nil,
        settingsStore: AppSettingsStore? = nil
    ) {
        let settingsStore = settingsStore ?? AppSettingsStore()
        self.calendar = calendar
        self.dateProvider = dateProvider
        self.workTimeCalculator = workTimeCalculator ?? WorkTimeCalculator()
        self.statisticsCalculator = statisticsCalculator ?? StatisticsCalculator()
        self.settingsStore = settingsStore

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .pad
        self.durationFormatter = formatter

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL yyyy"
        self.monthFormatter = monthFormatter

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        self.dateFormatter = dateFormatter

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        self.timeFormatter = timeFormatter

        refreshFormatterLocale()
    }

    func loadCurrentMonth(modelContext: ModelContext) {
        do {
            refreshFormatterLocale()
            let monthInterval = try currentMonthInterval()
            let repository = WorkDayRepository(modelContext: modelContext, calendar: calendar)
            let workDays = try repository.workDays(from: monthInterval.start, to: monthInterval.end)
            apply(workDays: workDays, monthStart: monthInterval.start)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    func beginAddingWorkDay() {
        canEditDate = true
        draftDate = calendar.startOfDay(for: dateProvider())
        draftCheckIn = defaultManualCheckIn(for: draftDate)
        draftCheckOut = defaultManualCheckOut(for: draftDate)
        draftLunchBreakMinutes = Int(settingsStore.defaultLunchBreakDuration / 60)
        editorTitle = dateFormatter.string(from: draftDate)
        isEditingWorkDay = true
    }

    func beginEditing(row: HistoryWorkDayRow, modelContext: ModelContext) {
        do {
            let repository = WorkDayRepository(modelContext: modelContext, calendar: calendar)
            let workDay = try repository.workDay(for: row.day)
            configureEditor(for: workDay, fallbackDate: row.day, canEditDate: false)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    func refreshDraftForSelectedDate(modelContext: ModelContext) {
        guard canEditDate else {
            return
        }

        do {
            let repository = WorkDayRepository(modelContext: modelContext, calendar: calendar)
            if let existingWorkDay = try repository.workDay(for: draftDate) {
                configureEditor(for: existingWorkDay, fallbackDate: draftDate, canEditDate: true)
            } else {
                draftDate = calendar.startOfDay(for: draftDate)
                draftCheckIn = defaultManualCheckIn(for: draftDate)
                draftCheckOut = defaultManualCheckOut(for: draftDate)
                editorTitle = dateFormatter.string(from: draftDate)
            }
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    func cancelEditingWorkDay() {
        isEditingWorkDay = false
    }

    func saveEditedWorkDay(modelContext: ModelContext) {
        do {
            let repository = WorkDayRepository(modelContext: modelContext, calendar: calendar)
            let service = WorkDayService(
                repository: repository,
                calendar: calendar,
                defaultLunchBreakDuration: settingsStore.defaultLunchBreakDuration
            )
            _ = try service.updateWorkDay(
                for: draftDate,
                checkIn: mergedDate(day: draftDate, time: draftCheckIn),
                checkOut: mergedDate(day: draftDate, time: draftCheckOut),
                lunchBreakDuration: TimeInterval(max(0, draftLunchBreakMinutes) * 60)
            )
            isEditingWorkDay = false
            loadCurrentMonth(modelContext: modelContext)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    private func configureEditor(for workDay: WorkDay?, fallbackDate: Date, canEditDate: Bool) {
        let now = dateProvider()
        let day = workDay?.day ?? fallbackDate
        self.canEditDate = canEditDate
        draftDate = calendar.startOfDay(for: day)
        draftCheckIn = workDay?.checkIn ?? dayWithTime(from: now, on: draftDate)
        draftLunchBreakMinutes = Int((workDay?.lunchBreakDuration ?? settingsStore.defaultLunchBreakDuration) / 60)
        draftCheckOut = workDay?.checkOut ?? defaultCheckOut(
            for: draftCheckIn,
            lunchBreakDuration: defaultDraftLunchBreakDuration,
            fallback: dayWithTime(from: now, on: draftDate)
        )
        editorTitle = dateFormatter.string(from: draftDate)
        isEditingWorkDay = true
    }

    private func apply(workDays: [WorkDay], monthStart: Date) {
        monthTitle = monthFormatter.string(from: monthStart)
        totalWorkedTimeText = formattedDuration(statisticsCalculator.totalWorkedTime(for: workDays))
        averageTimeAtWorkText = formattedDuration(statisticsCalculator.averageTimeAtWork(for: workDays))
        monthlyBalanceText = formattedSignedDuration(statisticsCalculator.accumulatedBalance(
            for: workDays,
            standardDuration: settingsStore.standardWorkdayDuration
        ))
        rows = workDays.map(row)
    }

    private func row(for workDay: WorkDay) -> HistoryWorkDayRow {
        let workedTime = workTimeCalculator.workedTime(for: workDay)
        let dailyBalanceText: String?
        if workDay.checkOut != nil {
            let dailyBalance = workTimeCalculator.dailyBalance(
                workedTime: workedTime,
                standardDuration: settingsStore.standardWorkdayDuration
            )
            dailyBalanceText = formattedSignedDuration(dailyBalance)
        } else {
            dailyBalanceText = nil
        }

        return HistoryWorkDayRow(
            id: workDay.persistentModelID,
            day: workDay.day,
            dateText: dateFormatter.string(from: workDay.day),
            checkInText: formattedTime(workDay.checkIn),
            checkOutText: formattedTime(workDay.checkOut),
            workedTimeText: formattedDuration(workedTime),
            dailyBalanceText: dailyBalanceText
        )
    }

    private func currentMonthInterval() throws -> (start: Date, end: Date) {
        let now = dateProvider()
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: now)
        else {
            throw HistoryViewModelError.monthIntervalUnavailable
        }

        return (monthInterval.start, monthInterval.end)
    }

    private func mergedDate(day: Date, time: Date) -> Date {
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: calendar.startOfDay(for: day)
        ) ?? day
    }

    private func dayWithTime(from time: Date, on day: Date) -> Date {
        mergedDate(day: day, time: time)
    }

    private func defaultManualCheckIn(for day: Date) -> Date {
        calendar.date(bySettingHour: 8, minute: 30, second: 0, of: calendar.startOfDay(for: day)) ?? day
    }

    private func defaultManualCheckOut(for day: Date) -> Date {
        calendar.date(bySettingHour: 17, minute: 15, second: 0, of: calendar.startOfDay(for: day)) ?? day
    }

    private func formattedTime(_ date: Date?) -> String? {
        guard let date else {
            return nil
        }

        return timeFormatter.string(from: date)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        durationFormatter.string(from: max(0, duration)) ?? ""
    }

    private var defaultDraftLunchBreakDuration: TimeInterval {
        TimeInterval(max(0, draftLunchBreakMinutes) * 60)
    }

    private func defaultCheckOut(
        for checkIn: Date?,
        lunchBreakDuration: TimeInterval,
        fallback: Date
    ) -> Date {
        workTimeCalculator.recommendedLeaveTime(
            checkIn: checkIn,
            lunchBreakDuration: lunchBreakDuration,
            standardDuration: settingsStore.standardWorkdayDuration
        ) ?? fallback
    }

    private func refreshFormatterLocale() {
        let locale = settingsStore.appLanguage.locale ?? .current
        var calendar = Calendar.current
        calendar.locale = locale
        durationFormatter.calendar = calendar
        monthFormatter.locale = locale
        dateFormatter.locale = locale
        timeFormatter.locale = locale
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
}

enum HistoryViewModelError: Error {
    case monthIntervalUnavailable
}
