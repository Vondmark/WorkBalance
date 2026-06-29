import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case ukrainian

    var id: String {
        rawValue
    }

    var locale: Locale? {
        switch self {
        case .system:
            nil
        case .english:
            Locale(identifier: "en")
        case .ukrainian:
            Locale(identifier: "uk")
        }
    }
}

final class AppSettingsStore {
    private enum Keys {
        static let standardWorkdayDuration = "settings.standardWorkdayDuration"
        static let defaultLunchBreakDuration = "settings.defaultLunchBreakDuration"
        static let appLanguage = "settings.appLanguage"
    }

    static let appLanguageKey = Keys.appLanguage

    static var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: WorkBalanceAppGroup.identifier) ?? .standard
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? Self.sharedUserDefaults
    }

    var standardWorkdayDuration: TimeInterval {
        guard userDefaults.object(forKey: Keys.standardWorkdayDuration) != nil else {
            return WorkBalanceDefaults.standardWorkdayDuration
        }

        return Self.validStandardWorkdayDuration(userDefaults.double(forKey: Keys.standardWorkdayDuration))
    }

    var defaultLunchBreakDuration: TimeInterval {
        guard userDefaults.object(forKey: Keys.defaultLunchBreakDuration) != nil else {
            return WorkBalanceDefaults.defaultLunchBreakDuration
        }

        return Self.validLunchBreakDuration(userDefaults.double(forKey: Keys.defaultLunchBreakDuration))
    }

    var appLanguage: AppLanguage {
        guard
            let rawValue = userDefaults.string(forKey: Keys.appLanguage),
            let language = AppLanguage(rawValue: rawValue)
        else {
            return .system
        }

        return language
    }

    func setStandardWorkdayDuration(_ duration: TimeInterval) {
        userDefaults.set(Self.validStandardWorkdayDuration(duration), forKey: Keys.standardWorkdayDuration)
    }

    func setDefaultLunchBreakDuration(_ duration: TimeInterval) {
        userDefaults.set(Self.validLunchBreakDuration(duration), forKey: Keys.defaultLunchBreakDuration)
    }

    func setAppLanguage(_ language: AppLanguage) {
        userDefaults.set(language.rawValue, forKey: Keys.appLanguage)
    }

    static func validStandardWorkdayDuration(_ duration: TimeInterval) -> TimeInterval {
        min(max(duration, 60 * 60), 16 * 60 * 60)
    }

    static func validLunchBreakDuration(_ duration: TimeInterval) -> TimeInterval {
        min(max(duration, 0), 3 * 60 * 60)
    }
}
