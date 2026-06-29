import Foundation

struct StatisticsCalculator {
    private let workTimeCalculator = WorkTimeCalculator()

    func completedWorkDays(from workDays: [WorkDay]) -> [WorkDay] {
        workDays.filter { workDay in
            workDay.checkIn != nil && workDay.checkOut != nil
        }
    }

    func totalWorkedTime(for workDays: [WorkDay]) -> TimeInterval {
        completedWorkDays(from: workDays).reduce(0) { total, workDay in
            total + workTimeCalculator.workedTime(for: workDay)
        }
    }

    func averageWorkedTime(for workDays: [WorkDay]) -> TimeInterval {
        let completedWorkDays = completedWorkDays(from: workDays)
        guard !completedWorkDays.isEmpty else {
            return 0
        }

        return totalWorkedTime(for: completedWorkDays) / Double(completedWorkDays.count)
    }

    func averageTimeAtWork(for workDays: [WorkDay]) -> TimeInterval {
        let completedWorkDays = completedWorkDays(from: workDays)
        guard !completedWorkDays.isEmpty else {
            return 0
        }

        let totalTimeAtWork = completedWorkDays.reduce(0) { total, workDay in
            total + workTimeCalculator.timeAtWork(for: workDay)
        }
        return totalTimeAtWork / Double(completedWorkDays.count)
    }

    func accumulatedBalance(
        for workDays: [WorkDay],
        standardDuration: TimeInterval = WorkBalanceDefaults.standardWorkdayDuration
    ) -> TimeInterval {
        completedWorkDays(from: workDays).reduce(0) { total, workDay in
            let workedTime = workTimeCalculator.workedTime(for: workDay)
            return total + workTimeCalculator.dailyBalance(
                workedTime: workedTime,
                standardDuration: standardDuration
            )
        }
    }
}
