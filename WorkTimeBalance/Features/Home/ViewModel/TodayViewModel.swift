import Foundation
import Observation
import SwiftData
import WidgetKit

enum TodayStatus {
    case notCheckedIn
    case checkedIn
    case checkedOut
}

enum TodayPrimaryAction {
    case checkIn
    case checkOut
}

@MainActor
@Observable
final class TodayViewModel {
    var checkIn: Date?
    var checkOut: Date?
    var isEditingToday = false
    var draftCheckIn = Date()
    var draftCheckOut = Date()
    var isEditingExistingCheckOut = false
    var currentTime = Date()
    var lastPersistenceError: Error?

    private let calculator: WorkTimeCalculator
    private let statisticsCalculator: StatisticsCalculator
    private let settingsStore: AppSettingsStore
    private let calendar: Calendar
    private let dateProvider: () -> Date
    private let durationFormatter: DateComponentsFormatter
    private let timeFormatter: DateFormatter

    var lunchBreakDuration: TimeInterval
    var standardWorkdayDuration: TimeInterval
    var currentMonthlyBalance: TimeInterval

    init(
        checkIn: Date? = nil,
        checkOut: Date? = nil,
        lunchBreakDuration: TimeInterval? = nil,
        standardWorkdayDuration: TimeInterval? = nil,
        currentMonthlyBalance: TimeInterval = 0,
        calculator: WorkTimeCalculator? = nil,
        statisticsCalculator: StatisticsCalculator? = nil,
        settingsStore: AppSettingsStore? = nil,
        calendar: Calendar = .current,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        let settingsStore = settingsStore ?? AppSettingsStore()
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.currentTime = dateProvider()
        self.lunchBreakDuration = lunchBreakDuration ?? settingsStore.defaultLunchBreakDuration
        self.standardWorkdayDuration = standardWorkdayDuration ?? settingsStore.standardWorkdayDuration
        self.currentMonthlyBalance = currentMonthlyBalance
        self.calculator = calculator ?? WorkTimeCalculator()
        self.statisticsCalculator = statisticsCalculator ?? StatisticsCalculator()
        self.settingsStore = settingsStore
        self.calendar = calendar
        self.dateProvider = dateProvider

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .pad
        self.durationFormatter = formatter

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        self.timeFormatter = timeFormatter
        refreshFormatterLocale()
    }

    var status: TodayStatus {
        if checkOut != nil {
            return .checkedOut
        }

        if checkIn != nil {
            return .checkedIn
        }

        return .notCheckedIn
    }

    var checkInText: String? {
        formattedTime(checkIn)
    }

    var checkOutText: String? {
        formattedTime(checkOut)
    }

    var workedTimeText: String {
        formattedDuration(workedTime)
    }

    var remainingTimeText: String {
        formattedDuration(remainingTime)
    }

    var recommendedLeaveTimeText: String? {
        formattedTime(recommendedLeaveTime)
    }

    var canUndoCheckOut: Bool {
        checkOut != nil
    }

    var primaryAction: TodayPrimaryAction? {
        switch status {
        case .notCheckedIn:
            .checkIn
        case .checkedIn:
            .checkOut
        case .checkedOut:
            nil
        }
    }

    var currentMonthlyBalanceText: String {
        formattedSignedDuration(currentMonthlyBalance)
    }

    var lunchBreakText: String {
        formattedDuration(lunchBreakDuration)
    }

    var standardWorkdayText: String {
        formattedDuration(standardWorkdayDuration)
    }

    func loadToday(modelContext: ModelContext) {
        do {
            refreshSettings()
            let service = makeWorkDayService(modelContext: modelContext)
            let workDay = try service.existingWorkDay(for: dateProvider())
            apply(workDay)
            currentMonthlyBalance = try monthlyBalance(modelContext: modelContext)
            refreshCurrentTime()
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    func checkInNow(modelContext: ModelContext) {
        do {
            refreshSettings()
            let now = dateProvider()
            let service = makeWorkDayService(modelContext: modelContext)
            let workDay = try service.checkIn(at: now, for: now)
            apply(workDay)
            currentMonthlyBalance = try monthlyBalance(modelContext: modelContext)
            refreshCurrentTime()
            reloadTodayWidget()
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    func checkOutNow(modelContext: ModelContext) {
        do {
            refreshSettings()
            let now = dateProvider()
            let service = makeWorkDayService(modelContext: modelContext)
            let workDay = try service.checkOut(at: now, for: now)
            apply(workDay)
            currentMonthlyBalance = try monthlyBalance(modelContext: modelContext)
            refreshCurrentTime()
            reloadTodayWidget()
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    func undoCheckOut(modelContext: ModelContext) {
        do {
            refreshSettings()
            let service = makeWorkDayService(modelContext: modelContext)
            let workDay = try service.undoCheckOut(for: dateProvider())
            apply(workDay)
            currentMonthlyBalance = try monthlyBalance(modelContext: modelContext)
            refreshCurrentTime()
            reloadTodayWidget()
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    func beginEditingToday() {
        refreshSettings()
        let now = dateProvider()
        draftCheckIn = checkIn ?? now
        isEditingExistingCheckOut = checkOut != nil
        draftCheckOut = checkOut ?? defaultCheckOut(for: draftCheckIn, fallback: now)
        isEditingToday = true
    }

    func cancelEditingToday() {
        isEditingToday = false
    }

    func saveEditedToday(modelContext: ModelContext) {
        do {
            refreshSettings()
            let service = makeWorkDayService(modelContext: modelContext)
            let workDay = try service.updateWorkDay(
                for: dateProvider(),
                checkIn: draftCheckIn,
                checkOut: isEditingExistingCheckOut ? draftCheckOut : nil
            )
            apply(workDay)
            currentMonthlyBalance = try monthlyBalance(modelContext: modelContext)
            refreshCurrentTime()
            isEditingToday = false
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }

    private func apply(_ workDay: WorkDay?) {
        checkIn = workDay?.checkIn
        checkOut = workDay?.checkOut
        lunchBreakDuration = workDay?.lunchBreakDuration ?? settingsStore.defaultLunchBreakDuration
    }

    private func makeWorkDayService(modelContext: ModelContext) -> WorkDayService {
        let repository = WorkDayRepository(modelContext: modelContext, calendar: calendar)
        return WorkDayService(
            repository: repository,
            calendar: calendar,
            defaultLunchBreakDuration: settingsStore.defaultLunchBreakDuration
        )
    }

    private func monthlyBalance(modelContext: ModelContext) throws -> TimeInterval {
        guard let monthInterval = calendar.dateInterval(of: .month, for: dateProvider()) else {
            return 0
        }

        let repository = WorkDayRepository(modelContext: modelContext, calendar: calendar)
        let workDays = try repository.workDays(from: monthInterval.start, to: monthInterval.end)
        return statisticsCalculator.accumulatedBalance(
            for: workDays,
            standardDuration: standardWorkdayDuration
        )
    }

    private func refreshSettings() {
        standardWorkdayDuration = settingsStore.standardWorkdayDuration
        if checkIn == nil && checkOut == nil {
            lunchBreakDuration = settingsStore.defaultLunchBreakDuration
        }
        refreshFormatterLocale()
    }

    private func refreshFormatterLocale() {
        let locale = settingsStore.appLanguage.locale ?? .current
        var calendar = Calendar.current
        calendar.locale = locale
        durationFormatter.calendar = calendar
        timeFormatter.locale = locale
    }

    private func defaultCheckOut(for checkIn: Date?, fallback: Date) -> Date {
        calculator.recommendedLeaveTime(
            checkIn: checkIn,
            lunchBreakDuration: lunchBreakDuration,
            standardDuration: standardWorkdayDuration
        ) ?? fallback
    }

    private var workedTime: TimeInterval {
        if checkOut == nil {
            return calculator.activeWorkedTime(
                checkIn: checkIn,
                currentTime: currentTime,
                standardDuration: standardWorkdayDuration
            )
        }

        return calculator.workedTime(
            checkIn: checkIn,
            checkOut: checkOut,
            lunchBreakDuration: lunchBreakDuration
        )
    }

    func refreshCurrentTime() {
        currentTime = dateProvider()
    }

    private var remainingTime: TimeInterval {
        if checkOut == nil {
            return calculator.activeRemainingTime(
                checkIn: checkIn,
                currentTime: currentTime,
                lunchBreakDuration: lunchBreakDuration,
                standardDuration: standardWorkdayDuration
            )
        }

        return calculator.remainingWorkTime(
            workedTime: workedTime,
            standardDuration: standardWorkdayDuration
        )
    }

    private var recommendedLeaveTime: Date? {
        calculator.recommendedLeaveTime(
            checkIn: checkIn,
            lunchBreakDuration: lunchBreakDuration,
            standardDuration: standardWorkdayDuration
        )
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

    private func reloadTodayWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: WorkBalanceWidgetKind.today)
    }
}
