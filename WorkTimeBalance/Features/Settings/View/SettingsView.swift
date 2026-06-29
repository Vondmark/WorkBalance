import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        selection: Binding(
                            get: { viewModel.appLanguage },
                            set: { viewModel.updateAppLanguage($0) }
                        )
                    ) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(TodayLocalization.Settings.title(for: language))
                                .tag(language)
                        }
                    } label: {
                        Text(TodayLocalization.Settings.appLanguage)
                    }
                } footer: {
                    Text(TodayLocalization.Settings.appLanguageFooter)
                }

                Section {
                    Stepper(
                        value: Binding(
                            get: { viewModel.standardWorkdayMinutes },
                            set: { viewModel.updateStandardWorkdayMinutes($0) }
                        ),
                        in: 60...(16 * 60),
                        step: 15
                    ) {
                        LabeledContent {
                            Text(viewModel.standardWorkdayText)
                                .foregroundStyle(.secondary)
                        } label: {
                            Text(TodayLocalization.Settings.standardWorkdayDuration)
                        }
                    }
                } footer: {
                    Text(TodayLocalization.Settings.standardWorkdayFooter)
                }

                Section {
                    Stepper(
                        value: Binding(
                            get: { viewModel.defaultLunchBreakMinutes },
                            set: { viewModel.updateDefaultLunchBreakMinutes($0) }
                        ),
                        in: 0...(3 * 60),
                        step: 5
                    ) {
                        LabeledContent {
                            Text(viewModel.defaultLunchBreakText)
                                .foregroundStyle(.secondary)
                        } label: {
                            Text(TodayLocalization.Settings.defaultLunchBreakDuration)
                        }
                    }
                } footer: {
                    Text(TodayLocalization.Settings.defaultLunchBreakFooter)
                }
            }
            .navigationTitle(TodayLocalization.Settings.title)
        }
    }
}

#Preview {
    SettingsView()
}
