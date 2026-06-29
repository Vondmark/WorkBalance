import SwiftData
import SwiftUI

private enum WorkBalanceTab: Hashable {
    case today
    case history
    case settings
}

struct ContentView: View {
    @AppStorage(
        AppSettingsStore.appLanguageKey,
        store: AppSettingsStore.sharedUserDefaults
    ) private var appLanguageRawValue = AppLanguage.system.rawValue

    @State private var selectedTab = WorkBalanceTab.today
    @State private var editTodayRequestID: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(editRequestID: editTodayRequestID)
                .tabItem {
                    Label {
                        Text(TodayLocalization.Today.title)
                    } icon: {
                        Image(systemName: "clock")
                    }
                }
                .tag(WorkBalanceTab.today)

            HistoryView()
                .tabItem {
                    Label {
                        Text(TodayLocalization.History.title)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
                .tag(WorkBalanceTab.history)

            SettingsView()
                .tabItem {
                    Label {
                        Text(TodayLocalization.Settings.title)
                    } icon: {
                        Image(systemName: "gearshape")
                    }
                }
                .tag(WorkBalanceTab.settings)
        }
        .environment(\.locale, appLanguage.locale ?? .current)
        .onOpenURL { url in
            guard url.scheme == "worktimebalance", url.host == "today", url.path == "/edit" else {
                return
            }

            selectedTab = .today
            editTodayRequestID = UUID()
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkDay.self, inMemory: true)
}
