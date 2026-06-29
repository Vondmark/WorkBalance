import Foundation

struct WorkTimeCalculator {
    func workedTime(
        checkIn: Date?,
        checkOut: Date?,
        lunchBreakDuration: TimeInterval = WorkBalanceDefaults.defaultLunchBreakDuration
    ) -> TimeInterval {
        guard let checkIn, let checkOut, checkOut > checkIn else {
            return 0
        }

        let grossDuration = checkOut.timeIntervalSince(checkIn)
        return max(0, grossDuration - lunchBreakDuration)
    }

    func workedTime(for workDay: WorkDay) -> TimeInterval {
        workedTime(
            checkIn: workDay.checkIn,
            checkOut: workDay.checkOut,
            lunchBreakDuration: workDay.lunchBreakDuration
        )
    }

    func timeAtWork(checkIn: Date?, checkOut: Date?) -> TimeInterval {
        guard let checkIn, let checkOut, checkOut > checkIn else {
            return 0
        }

        return checkOut.timeIntervalSince(checkIn)
    }

    func timeAtWork(for workDay: WorkDay) -> TimeInterval {
        timeAtWork(checkIn: workDay.checkIn, checkOut: workDay.checkOut)
    }

    func remainingWorkTime(
        workedTime: TimeInterval,
        standardDuration: TimeInterval = WorkBalanceDefaults.standardWorkdayDuration
    ) -> TimeInterval {
        max(0, standardDuration - workedTime)
    }

    func activeWorkedTime(
        checkIn: Date?,
        currentTime: Date,
        standardDuration: TimeInterval = WorkBalanceDefaults.standardWorkdayDuration
    ) -> TimeInterval {
        guard let checkIn, currentTime > checkIn else {
            return 0
        }

        return min(currentTime.timeIntervalSince(checkIn), standardDuration)
    }

    func activeRemainingTime(
        checkIn: Date?,
        currentTime: Date,
        lunchBreakDuration: TimeInterval = WorkBalanceDefaults.defaultLunchBreakDuration,
        standardDuration: TimeInterval = WorkBalanceDefaults.standardWorkdayDuration
    ) -> TimeInterval {
        guard let leaveTime = recommendedLeaveTime(
            checkIn: checkIn,
            lunchBreakDuration: lunchBreakDuration,
            standardDuration: standardDuration
        ), leaveTime > currentTime else {
            return 0
        }

        return leaveTime.timeIntervalSince(currentTime)
    }

    func recommendedLeaveTime(
        checkIn: Date?,
        lunchBreakDuration: TimeInterval = WorkBalanceDefaults.defaultLunchBreakDuration,
        standardDuration: TimeInterval = WorkBalanceDefaults.standardWorkdayDuration
    ) -> Date? {
        guard let checkIn else {
            return nil
        }

        return checkIn.addingTimeInterval(lunchBreakDuration + standardDuration)
    }

    func dailyBalance(
        workedTime: TimeInterval,
        standardDuration: TimeInterval = WorkBalanceDefaults.standardWorkdayDuration
    ) -> TimeInterval {
        workedTime - standardDuration
    }
}
