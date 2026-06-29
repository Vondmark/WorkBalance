import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var standardWorkdayMinutes: Int
    var defaultLunchBreakMinutes: Int
    var appLanguage: AppLanguage

    private let settingsStore: AppSettingsStore
    private let durationFormatter: DateComponentsFormatter

    init(settingsStore: AppSettingsStore? = nil) {
        let settingsStore = settingsStore ?? AppSettingsStore()
        self.settingsStore = settingsStore
        self.standardWorkdayMinutes = Int(settingsStore.standardWorkdayDuration / 60)
        self.defaultLunchBreakMinutes = Int(settingsStore.defaultLunchBreakDuration / 60)
        self.appLanguage = settingsStore.appLanguage

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .pad
        self.durationFormatter = formatter
        refreshFormatterLocale()
    }

    var standardWorkdayText: String {
        formattedDuration(TimeInterval(standardWorkdayMinutes * 60))
    }

    var defaultLunchBreakText: String {
        formattedDuration(TimeInterval(defaultLunchBreakMinutes * 60))
    }

    func updateStandardWorkdayMinutes(_ minutes: Int) {
        standardWorkdayMinutes = clamped(minutes, minimum: 60, maximum: 16 * 60)
        settingsStore.setStandardWorkdayDuration(TimeInterval(standardWorkdayMinutes * 60))
    }

    func updateDefaultLunchBreakMinutes(_ minutes: Int) {
        defaultLunchBreakMinutes = clamped(minutes, minimum: 0, maximum: 3 * 60)
        settingsStore.setDefaultLunchBreakDuration(TimeInterval(defaultLunchBreakMinutes * 60))
    }

    func updateAppLanguage(_ language: AppLanguage) {
        appLanguage = language
        settingsStore.setAppLanguage(language)
        refreshFormatterLocale()
    }

    private func clamped(_ value: Int, minimum: Int, maximum: Int) -> Int {
        min(max(value, minimum), maximum)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        durationFormatter.string(from: duration) ?? ""
    }

    private func refreshFormatterLocale() {
        var calendar = Calendar.current
        calendar.locale = appLanguage.locale ?? .current
        durationFormatter.calendar = calendar
    }
}
