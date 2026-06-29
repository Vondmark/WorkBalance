import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
#endif

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    monthSummaryGrid
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text(viewModel.monthTitle)
                }

                Section {
                    if viewModel.rows.isEmpty {
                        Text(TodayLocalization.History.emptyState)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.rows) { row in
                            Button {
                                viewModel.beginEditing(row: row, modelContext: modelContext)
                            } label: {
                                HistoryWorkDayRowView(row: row)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text(TodayLocalization.History.workdaysSection)
                }
            }
            .workBalanceHistoryListStyle()
            .navigationTitle(TodayLocalization.History.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.beginAddingWorkDay()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(TodayLocalization.History.addWorkday)
                }
            }
            .onAppear {
                viewModel.loadCurrentMonth(modelContext: modelContext)
            }
            .sheet(isPresented: $viewModel.isEditingWorkDay) {
                HistoryWorkDayEditorView(viewModel: viewModel, modelContext: modelContext)
            }
        }
    }

    private var monthSummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
            HistorySummaryCard(
                title: TodayLocalization.History.totalWorkedTime,
                value: viewModel.totalWorkedTimeText,
                systemImage: "timer"
            )

            HistorySummaryCard(
                title: TodayLocalization.History.averageTimeAtWork,
                value: viewModel.averageTimeAtWorkText,
                systemImage: "chart.bar"
            )

            HistorySummaryCard(
                title: TodayLocalization.History.monthlyBalance,
                value: viewModel.monthlyBalanceText,
                systemImage: "calendar.badge.clock"
            )
        }
        .padding(.vertical, 8)
    }
}

private extension View {
    @ViewBuilder
    func workBalanceHistoryListStyle() -> some View {
#if os(iOS)
        self.listStyle(.insetGrouped)
#else
        self.listStyle(.automatic)
#endif
    }
}

private struct HistoryWorkDayEditorView: View {
    @Bindable var viewModel: HistoryViewModel
    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            editorContent
            .navigationTitle(viewModel.editorTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.cancelEditingWorkDay()
                    } label: {
                        Text(TodayLocalization.Common.cancel)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.saveEditedWorkDay(modelContext: modelContext)
                    } label: {
                        Text(TodayLocalization.Common.save)
                    }
                }
            }
        }
        .workBalanceEditorSheetFrame()
    }

    @ViewBuilder
    private var editorContent: some View {
#if os(macOS)
        VStack(alignment: .leading, spacing: 16) {
            macOSEditorDatePicker(
                title: TodayLocalization.History.date,
                selection: $viewModel.draftDate,
                displayedComponents: [.date]
            )
            .disabled(!viewModel.canEditDate)
            .onChange(of: viewModel.draftDate) { _, _ in
                viewModel.refreshDraftForSelectedDate(modelContext: modelContext)
            }

            macOSEditorDatePicker(
                title: TodayLocalization.Today.checkInTime,
                selection: $viewModel.draftCheckIn,
                displayedComponents: [.hourAndMinute]
            )

            macOSEditorDatePicker(
                title: TodayLocalization.Today.checkOutTime,
                selection: $viewModel.draftCheckOut,
                displayedComponents: [.hourAndMinute]
            )

            LabeledContent {
                Stepper(value: $viewModel.draftLunchBreakMinutes, in: 0...180, step: 5) {
                    Text(viewModel.draftLunchBreakText)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 160, alignment: .trailing)
            } label: {
                Text(TodayLocalization.Today.lunchBreak)
            }
        }
        .padding(24)
#else
        Form {
            Section {
                DatePicker(
                    selection: $viewModel.draftDate,
                    displayedComponents: [.date]
                ) {
                    Text(TodayLocalization.History.date)
                }
                .disabled(!viewModel.canEditDate)
                .onChange(of: viewModel.draftDate) { _, _ in
                    viewModel.refreshDraftForSelectedDate(modelContext: modelContext)
                }
            }

            Section {
                DatePicker(
                    selection: $viewModel.draftCheckIn,
                    displayedComponents: [.hourAndMinute]
                ) {
                    Text(TodayLocalization.Today.checkInTime)
                }
            }

            Section {
                DatePicker(
                    selection: $viewModel.draftCheckOut,
                    displayedComponents: [.hourAndMinute]
                ) {
                    Text(TodayLocalization.Today.checkOutTime)
                }
            }

            Section {
                Stepper(value: $viewModel.draftLunchBreakMinutes, in: 0...180, step: 5) {
                    HStack {
                        Text(TodayLocalization.Today.lunchBreak)
                        Spacer()
                        Text(viewModel.draftLunchBreakText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
#endif
    }

#if os(macOS)
    private func macOSEditorDatePicker(
        title: LocalizedStringKey,
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents
    ) -> some View {
        LabeledContent {
            DatePicker(
                "",
                selection: selection,
                displayedComponents: displayedComponents
            )
            .labelsHidden()
            .frame(width: 160, alignment: .trailing)
        } label: {
            Text(title)
        }
    }
#endif
}

private extension View {
    @ViewBuilder
    func workBalanceEditorSheetFrame() -> some View {
#if os(macOS)
        self.frame(minWidth: 520, idealWidth: 560, minHeight: 320, idealHeight: 360)
#else
        self
#endif
    }
}

private struct HistorySummaryCard: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 34, alignment: .topLeading)

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
        .background(Self.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    private static var cardBackground: Color {
#if os(iOS)
        Color(.secondarySystemGroupedBackground)
#elseif os(macOS)
        Color(nsColor: .controlBackgroundColor)
#else
        Color(.background)
#endif
    }
}

private struct HistoryWorkDayRowView: View {
    let row: HistoryWorkDayRow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(row.dateText)
                    .font(.headline)

                Spacer()

                if let dailyBalanceText = row.dailyBalanceText {
                    Text(dailyBalanceText)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    HistoryMetricView(
                        title: TodayLocalization.History.checkIn,
                        value: row.checkInText
                    )

                    HistoryMetricView(
                        title: TodayLocalization.History.checkOut,
                        value: row.checkOutText
                    )
                }

                GridRow {
                    HistoryMetricView(
                        title: TodayLocalization.History.workedTime,
                        value: row.workedTimeText
                    )

                    if let dailyBalanceText = row.dailyBalanceText {
                        HistoryMetricView(
                            title: TodayLocalization.History.dailyBalance,
                            value: dailyBalanceText
                        )
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct HistoryMetricView: View {
    let title: LocalizedStringKey
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let value {
                Text(value)
                    .font(.subheadline.weight(.semibold))
            } else {
                Text(TodayLocalization.Common.notSet)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HistoryView()
        .modelContainer(historyPreviewContainer)
}

@MainActor
private let historyPreviewContainer: ModelContainer = {
    let schema = Schema([WorkDay.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let calendar = Calendar.current
    let now = Date()

    func date(dayOffset: Int, hour: Int = 0, minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
        let startOfDay = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) ?? startOfDay
    }

    let workDays = [
        WorkDay(
            day: date(dayOffset: 0),
            checkIn: date(dayOffset: 0, hour: 8, minute: 45),
            checkOut: nil
        ),
        WorkDay(
            day: date(dayOffset: -1),
            checkIn: date(dayOffset: -1, hour: 8, minute: 30),
            checkOut: date(dayOffset: -1, hour: 17, minute: 15)
        ),
        WorkDay(
            day: date(dayOffset: -2),
            checkIn: date(dayOffset: -2, hour: 8, minute: 15),
            checkOut: date(dayOffset: -2, hour: 18, minute: 0)
        ),
        WorkDay(
            day: date(dayOffset: -3),
            checkIn: date(dayOffset: -3, hour: 9),
            checkOut: date(dayOffset: -3, hour: 16, minute: 45)
        )
    ]

    for workDay in workDays {
        container.mainContext.insert(workDay)
    }

    return container
}()
