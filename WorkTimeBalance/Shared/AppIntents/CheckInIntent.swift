import AppIntents
import SwiftData
import WidgetKit

struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource { "intent.checkIn.title" }
    static var description: IntentDescription { "intent.checkIn.description" }
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let now = Date()
        let container = try WorkBalanceModelContainerFactory.makeSharedModelContainer()
        let modelContext = ModelContext(container)
        let repository = WorkDayRepository(modelContext: modelContext)
        let settingsStore = AppSettingsStore()
        let service = WorkDayService(
            repository: repository,
            defaultLunchBreakDuration: settingsStore.defaultLunchBreakDuration
        )

        if let workDay = try service.existingWorkDay(for: now), workDay.checkIn != nil {
            WidgetCenter.shared.reloadTimelines(ofKind: WorkBalanceWidgetKind.today)
            return .result(dialog: IntentDialog(LocalizedStringResource("intent.checkIn.alreadyExists")))
        }

        _ = try service.checkIn(at: now, for: now)
        WidgetCenter.shared.reloadTimelines(ofKind: WorkBalanceWidgetKind.today)
        return .result(dialog: IntentDialog(LocalizedStringResource("intent.checkIn.success")))
    }
}
