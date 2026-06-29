import Foundation
import Testing
@testable import WorkTimeBalance

struct AppSettingsStoreTests {
    @Test func returnsDefaultSettingsWhenValuesAreMissing() throws {
        let userDefaults = try makeUserDefaults()
        let store = AppSettingsStore(userDefaults: userDefaults)

        #expect(store.standardWorkdayDuration == WorkBalanceDefaults.standardWorkdayDuration)
        #expect(store.defaultLunchBreakDuration == WorkBalanceDefaults.defaultLunchBreakDuration)
        #expect(store.appLanguage == .system)
    }

    @Test func allowsZeroLunchBreak() throws {
        let userDefaults = try makeUserDefaults()
        let store = AppSettingsStore(userDefaults: userDefaults)

        store.setDefaultLunchBreakDuration(0)

        #expect(store.defaultLunchBreakDuration == 0)
    }

    @Test func clampsUnrealisticValues() throws {
        let userDefaults = try makeUserDefaults()
        let store = AppSettingsStore(userDefaults: userDefaults)

        store.setStandardWorkdayDuration(30 * 60)
        store.setDefaultLunchBreakDuration(4 * 60 * 60)

        #expect(store.standardWorkdayDuration == 60 * 60)
        #expect(store.defaultLunchBreakDuration == 3 * 60 * 60)
    }

    @Test func savesAppLanguage() throws {
        let userDefaults = try makeUserDefaults()
        let store = AppSettingsStore(userDefaults: userDefaults)

        store.setAppLanguage(.ukrainian)

        #expect(store.appLanguage == .ukrainian)
        #expect(store.appLanguage.locale?.identifier == "uk")
    }

    private func makeUserDefaults() throws -> UserDefaults {
        let suiteName = "AppSettingsStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
