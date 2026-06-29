import AppIntents
import SwiftData
import WidgetKit

struct CheckOutIntent: AppIntent {
    static var title: LocalizedStringResource { "intent.checkOut.title" }
    static var description: IntentDescription { "intent.checkOut.description" }
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

        _ = try service.checkOut(at: now, for: now)
        WidgetCenter.shared.reloadTimelines(ofKind: WorkBalanceWidgetKind.today)
        return .result(dialog: IntentDialog(LocalizedStringResource("intent.checkOut.success")))
    }
}
