import SwiftUI

enum TodayLocalization {
    enum Common {
        static let cancel: LocalizedStringKey = "common.cancel"
        static let notSet: LocalizedStringKey = "common.notSet"
        static let save: LocalizedStringKey = "common.save"
    }

    enum History {
        static let title: LocalizedStringKey = "history.title"
        static let addWorkday: LocalizedStringKey = "history.addWorkday"
        static let totalWorkedTime: LocalizedStringKey = "history.totalWorkedTime"
        static let averageTimeAtWork: LocalizedStringKey = "history.averageTimeAtWork"
        static let monthlyBalance: LocalizedStringKey = "history.monthlyBalance"
        static let workdaysSection: LocalizedStringKey = "history.section.workdays"
        static let emptyState: LocalizedStringKey = "history.emptyState"
        static let editPlaceholderTitle: LocalizedStringKey = "history.editPlaceholder.title"
        static let editPlaceholderMessage: LocalizedStringKey = "history.editPlaceholder.message"
        static let date: LocalizedStringKey = "history.row.date"
        static let checkIn: LocalizedStringKey = "history.row.checkIn"
        static let checkOut: LocalizedStringKey = "history.row.checkOut"
        static let workedTime: LocalizedStringKey = "history.row.workedTime"
        static let dailyBalance: LocalizedStringKey = "history.row.dailyBalance"
    }

    enum Settings {
        static let title: LocalizedStringKey = "settings.title"
        static let appLanguage: LocalizedStringKey = "settings.appLanguage"
        static let appLanguageFooter: LocalizedStringKey = "settings.appLanguageFooter"
        static let standardWorkdayDuration: LocalizedStringKey = "settings.standardWorkdayDuration"
        static let standardWorkdayFooter: LocalizedStringKey = "settings.standardWorkdayFooter"
        static let defaultLunchBreakDuration: LocalizedStringKey = "settings.defaultLunchBreakDuration"
        static let defaultLunchBreakFooter: LocalizedStringKey = "settings.defaultLunchBreakFooter"

        static func title(for language: AppLanguage) -> LocalizedStringKey {
            switch language {
            case .system:
                "settings.language.system"
            case .english:
                "settings.language.english"
            case .ukrainian:
                "settings.language.ukrainian"
            }
        }
    }

    enum Today {
        static let title: LocalizedStringKey = "today.title"
        static let statusTitle: LocalizedStringKey = "today.status.title"
        static let checkInTime: LocalizedStringKey = "today.checkInTime"
        static let checkOutTime: LocalizedStringKey = "today.checkOutTime"
        static let workedTime: LocalizedStringKey = "today.workedTime"
        static let remainingTime: LocalizedStringKey = "today.remainingTime"
        static let recommendedLeaveTime: LocalizedStringKey = "today.recommendedLeaveTime"
        static let monthlyBalance: LocalizedStringKey = "today.monthlyBalance"
        static let lunchBreak: LocalizedStringKey = "today.lunchBreak"
        static let standardWorkday: LocalizedStringKey = "today.standardWorkday"
        static let summarySection: LocalizedStringKey = "today.section.summary"
        static let scheduleSection: LocalizedStringKey = "today.section.schedule"
        static let settingsSection: LocalizedStringKey = "today.section.settings"

        enum Edit {
            static let title: LocalizedStringKey = "today.edit.title"
        }

        enum Actions {
            static let checkIn: LocalizedStringKey = "today.actions.checkIn"
            static let checkOut: LocalizedStringKey = "today.actions.checkOut"
            static let editToday: LocalizedStringKey = "today.actions.editToday"
            static let undoCheckOut: LocalizedStringKey = "today.actions.undoCheckOut"
        }

        static func status(_ status: TodayStatus) -> LocalizedStringKey {
            switch status {
            case .notCheckedIn:
                "today.status.notCheckedIn"
            case .checkedIn:
                "today.status.checkedIn"
            case .checkedOut:
                "today.status.checkedOut"
            }
        }
    }
}
