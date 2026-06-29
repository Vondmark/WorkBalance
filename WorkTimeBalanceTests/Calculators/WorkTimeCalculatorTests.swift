import Foundation
import Testing
@testable import WorkTimeBalance

struct WorkTimeCalculatorTests {
    private let calculator = WorkTimeCalculator()

    @Test func workedTimeSubtractsLunchBreak() {
        let checkIn = Date(timeIntervalSinceReferenceDate: 0)
        let checkOut = checkIn.addingTimeInterval((8 * 60 * 60) + (45 * 60))

        let workedTime = calculator.workedTime(
            checkIn: checkIn,
            checkOut: checkOut,
            lunchBreakDuration: WorkBalanceDefaults.defaultLunchBreakDuration
        )

        #expect(workedTime == WorkBalanceDefaults.standardWorkdayDuration)
    }

    @Test func workedTimeReturnsZeroWithoutCompleteDay() {
        let checkIn = Date(timeIntervalSinceReferenceDate: 0)

        let workedTime = calculator.workedTime(checkIn: checkIn, checkOut: nil)

        #expect(workedTime == 0)
    }

    @Test func recommendedLeaveTimeUsesStandardWorkdayAndLunchBreak() throws {
        let checkIn = Date(timeIntervalSinceReferenceDate: 0)

        let leaveTime = try #require(calculator.recommendedLeaveTime(checkIn: checkIn))

        #expect(leaveTime == checkIn.addingTimeInterval(
            WorkBalanceDefaults.standardWorkdayDuration + WorkBalanceDefaults.defaultLunchBreakDuration
        ))
    }

    @Test func recommendedLeaveTimeForEightThirtyCheckInIsFiveFifteen() throws {
        let calendar = Calendar(identifier: .gregorian)
        let checkIn = try #require(calendar.date(from: DateComponents(hour: 8, minute: 30)))
        let expectedLeaveTime = try #require(calendar.date(from: DateComponents(hour: 17, minute: 15)))

        let leaveTime = try #require(calculator.recommendedLeaveTime(checkIn: checkIn))

        #expect(leaveTime == expectedLeaveTime)
    }

    @Test func activeWorkedTimeDoesNotSubtractFutureLunchBreak() throws {
        let calendar = Calendar(identifier: .gregorian)
        let checkIn = try #require(calendar.date(from: DateComponents(hour: 8, minute: 45)))
        let currentTime = try #require(calendar.date(from: DateComponents(hour: 9, minute: 48)))

        let workedTime = calculator.activeWorkedTime(checkIn: checkIn, currentTime: currentTime)

        #expect(workedTime == 63 * 60)
    }

}
