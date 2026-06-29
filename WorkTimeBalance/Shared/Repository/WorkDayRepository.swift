import Foundation
import SwiftData

@MainActor
final class WorkDayRepository {
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    func workDay(for date: Date) throws -> WorkDay? {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        var descriptor = FetchDescriptor<WorkDay>(
            predicate: #Predicate { workDay in
                workDay.day >= startOfDay && workDay.day < endOfDay
            },
            sortBy: [SortDescriptor(\WorkDay.day)]
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    func workDays(from startDate: Date, to endDate: Date) throws -> [WorkDay] {
        let descriptor = FetchDescriptor<WorkDay>(
            predicate: #Predicate { workDay in
                workDay.day >= startDate && workDay.day < endDate
            },
            sortBy: [SortDescriptor(\WorkDay.day, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    func createWorkDay(for date: Date) -> WorkDay {
        let workDay = WorkDay(day: calendar.startOfDay(for: date))
        modelContext.insert(workDay)
        return workDay
    }

    func save() throws {
        try modelContext.save()
    }
}
