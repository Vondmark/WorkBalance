import Foundation

@MainActor
final class WorkDayService {
    private let repository: WorkDayRepository
    private let calendar: Calendar
    private let defaultLunchBreakDuration: TimeInterval

    init(
        repository: WorkDayRepository,
        calendar: Calendar = .current,
        defaultLunchBreakDuration: TimeInterval? = nil
    ) {
        self.repository = repository
        self.calendar = calendar
        self.defaultLunchBreakDuration = defaultLunchBreakDuration ?? WorkBalanceDefaults.defaultLunchBreakDuration
    }

    func existingWorkDay(for date: Date) throws -> WorkDay? {
        try repository.workDay(for: date)
    }

    func workDay(for date: Date) throws -> WorkDay {
        if let existingWorkDay = try repository.workDay(for: date) {
            return existingWorkDay
        }

        let workDay = repository.createWorkDay(for: calendar.startOfDay(for: date))
        workDay.lunchBreakDuration = defaultLunchBreakDuration
        return workDay
    }

    func checkIn(at checkInDate: Date, for date: Date) throws -> WorkDay {
        let workDay = try workDay(for: date)

        if workDay.checkIn == nil {
            workDay.checkIn = checkInDate
            workDay.updatedAt = Date.now
            try repository.save()
        }

        return workDay
    }

    func checkOut(at checkOutDate: Date, for date: Date) throws -> WorkDay {
        let workDay = try workDay(for: date)
        workDay.checkOut = checkOutDate
        workDay.updatedAt = Date.now
        try repository.save()
        return workDay
    }

    func undoCheckOut(for date: Date) throws -> WorkDay? {
        guard let workDay = try repository.workDay(for: date) else {
            return nil
        }

        workDay.checkOut = nil
        workDay.updatedAt = Date.now
        try repository.save()
        return workDay
    }

    func updateWorkDay(
        for date: Date,
        checkIn: Date?,
        checkOut: Date?,
        lunchBreakDuration: TimeInterval? = nil
    ) throws -> WorkDay {
        let workDay = try workDay(for: date)
        workDay.checkIn = checkIn
        workDay.checkOut = normalizedCheckOut(checkIn: checkIn, checkOut: checkOut)
        if let lunchBreakDuration {
            workDay.lunchBreakDuration = lunchBreakDuration
        }
        workDay.updatedAt = Date.now
        try repository.save()
        return workDay
    }

    private func normalizedCheckOut(checkIn: Date?, checkOut: Date?) -> Date? {
        guard let checkIn, let checkOut, checkOut < checkIn else {
            return checkOut
        }

        return checkIn
    }
}
