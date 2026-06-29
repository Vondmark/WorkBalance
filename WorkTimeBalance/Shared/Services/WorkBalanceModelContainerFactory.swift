import SwiftData

enum WorkBalanceModelContainerFactory {
    static let schema = Schema([
        Item.self,
        WorkDay.self,
    ])

    static func makeSharedModelContainer() throws -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(WorkBalanceAppGroup.identifier)
        )

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}
