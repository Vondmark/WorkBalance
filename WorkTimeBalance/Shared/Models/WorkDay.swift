import Foundation
import SwiftData

@Model
final class WorkDay {
    var day: Date
    var checkIn: Date?
    var checkOut: Date?
    var lunchBreakDuration: TimeInterval
    var createdAt: Date
    var updatedAt: Date

    init(
        day: Date,
        checkIn: Date? = nil,
        checkOut: Date? = nil,
        lunchBreakDuration: TimeInterval = WorkBalanceDefaults.defaultLunchBreakDuration,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.day = day
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.lunchBreakDuration = lunchBreakDuration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
