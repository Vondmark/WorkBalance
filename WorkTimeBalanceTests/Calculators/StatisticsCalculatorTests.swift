import Foundation
import Testing
@testable import WorkTimeBalance

struct StatisticsCalculatorTests {
    private let calculator = StatisticsCalculator()

    @Test func monthlyStatisticsUseCompletedWorkDaysOnly() {
        let baseDate = Date(timeIntervalSinceReferenceDate: 0)
        let completedStandardDay = WorkDay(
            day: baseDate,
            checkIn: baseDate,
            checkOut: baseDate.addingTimeInterval((8 * 60 * 60) + (45 * 60))
        )
        let completedOvertimeDay = WorkDay(
            day: baseDate.addingTimeInterval(24 * 60 * 60),
            checkIn: baseDate,
            checkOut: baseDate.addingTimeInterval((9 * 60 * 60) + (45 * 60))
        )
        let activeDay = WorkDay(
            day: baseDate.addingTimeInterval(2 * 24 * 60 * 60),
            checkIn: baseDate,
            checkOut: nil
        )

        let workDays = [completedStandardDay, completedOvertimeDay, activeDay]

        #expect(calculator.totalWorkedTime(for: workDays) == 17 * 60 * 60)
        #expect(calculator.averageWorkedTime(for: workDays) == (8 * 60 * 60) + (30 * 60))
        #expect(calculator.averageTimeAtWork(for: workDays) == (9 * 60 * 60) + (15 * 60))
        #expect(calculator.accumulatedBalance(for: workDays) == 60 * 60)
    }

    @Test func activeCurrentDayIsExcludedUntilCheckoutIsSet() {
        let baseDate = Date(timeIntervalSinceReferenceDate: 0)
        let currentDay = WorkDay(
            day: baseDate,
            checkIn: baseDate,
            checkOut: nil
        )

        #expect(calculator.accumulatedBalance(for: [currentDay]) == 0)

        currentDay.checkOut = baseDate.addingTimeInterval((9 * 60 * 60) + (45 * 60))
        #expect(calculator.accumulatedBalance(for: [currentDay]) == 60 * 60)

        currentDay.checkOut = nil
        #expect(calculator.accumulatedBalance(for: [currentDay]) == 0)
    }
}
