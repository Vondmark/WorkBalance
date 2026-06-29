//
//  WorkTimeBalanceApp.swift
//  WorkTimeBalance
//
//  Created by Mark on 28.06.2026.
//

import SwiftUI
import SwiftData

@main
struct WorkTimeBalanceApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try WorkBalanceModelContainerFactory.makeSharedModelContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
