import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
#endif

struct TodayView: View {
    let editRequestID: UUID?

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()

    init(editRequestID: UUID? = nil) {
        self.editRequestID = editRequestID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    scheduleCard
                    summaryCard
                    secondaryActions
                }
                .padding()
                .padding(.bottom, 96)
            }
            .background(Self.groupedBackground)
            .navigationTitle(TodayLocalization.Today.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.beginEditingToday()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel(TodayLocalization.Today.Actions.editToday)
                }
            }
            .safeAreaInset(edge: .bottom) {
                primaryActionBar
            }
            .sheet(isPresented: $viewModel.isEditingToday) {
                TodayEditSheet(viewModel: viewModel, modelContext: modelContext)
            }
            .onAppear {
                viewModel.loadToday(modelContext: modelContext)
            }
            .onChange(of: editRequestID) { _, requestID in
                guard requestID != nil else {
                    return
                }

                viewModel.loadToday(modelContext: modelContext)
                viewModel.beginEditingToday()
            }
            .task {
                while !Task.isCancelled {
                    viewModel.refreshCurrentTime()
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }
    }

    private static var groupedBackground: Color {
#if os(iOS)
        Color(.systemGroupedBackground)
#elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
#else
        Color(.background)
#endif
    }

    private var statusCard: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text(TodayLocalization.Today.statusTitle)
                } icon: {
                    Image(systemName: "clock.badge")
                }
                .font(.headline)

                Text(TodayLocalization.Today.status(viewModel.status))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var scheduleCard: some View {
        TodayCard {
            VStack(spacing: 14) {
                Button {
                    viewModel.beginEditingToday()
                } label: {
                    TodayValueRow(
                        title: TodayLocalization.Today.checkInTime,
                        value: viewModel.checkInText,
                        systemImage: "arrow.right.circle",
                        showsEditIndicator: true
                    )
                }
                .buttonStyle(.plain)

                Divider()

                Button {
                    viewModel.beginEditingToday()
                } label: {
                    TodayValueRow(
                        title: TodayLocalization.Today.checkOutTime,
                        value: viewModel.checkOutText,
                        systemImage: "arrow.left.circle",
                        showsEditIndicator: true
                    )
                }
                .buttonStyle(.plain)

                Divider()

                TodayValueRow(
                    title: TodayLocalization.Today.recommendedLeaveTime,
                    value: viewModel.recommendedLeaveTimeText,
                    systemImage: "figure.walk.departure"
                )
            }
        }
    }

    private var summaryCard: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(TodayLocalization.Today.summarySection)
                    .font(.headline)

                TodayValueRow(
                    title: TodayLocalization.Today.workedTime,
                    value: viewModel.workedTimeText,
                    systemImage: "timer"
                )

                Divider()

                TodayValueRow(
                    title: TodayLocalization.Today.remainingTime,
                    value: viewModel.remainingTimeText,
                    systemImage: "hourglass"
                )

                Divider()

                TodayValueRow(
                    title: TodayLocalization.Today.monthlyBalance,
                    value: viewModel.currentMonthlyBalanceText,
                    systemImage: "calendar.badge.clock"
                )
            }
        }
    }

    private var primaryActionBar: some View {
        Group {
            if let primaryAction = viewModel.primaryAction {
                Button {
                    perform(primaryAction)
                } label: {
                    TodayActionButtonLabel(
                        title: title(for: primaryAction),
                        systemImage: systemImage(for: primaryAction)
                    )
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(.bar)
            }
        }
    }

    private var secondaryActions: some View {
        VStack(spacing: 12) {
            if viewModel.canUndoCheckOut {
                Button {
                    viewModel.undoCheckOut(modelContext: modelContext)
                } label: {
                    TodayActionButtonLabel(
                        title: TodayLocalization.Today.Actions.undoCheckOut,
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func perform(_ action: TodayPrimaryAction) {
        switch action {
        case .checkIn:
            viewModel.checkInNow(modelContext: modelContext)
        case .checkOut:
            viewModel.checkOutNow(modelContext: modelContext)
        }
    }

    private func title(for action: TodayPrimaryAction) -> LocalizedStringKey {
        switch action {
        case .checkIn:
            TodayLocalization.Today.Actions.checkIn
        case .checkOut:
            TodayLocalization.Today.Actions.checkOut
        }
    }

    private func systemImage(for action: TodayPrimaryAction) -> String {
        switch action {
        case .checkIn:
            "play.fill"
        case .checkOut:
            "stop.fill"
        }
    }
}

private struct TodayActionButtonLabel: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
        } icon: {
            Image(systemName: systemImage)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
    }
}

private struct TodayEditSheet: View {
    @Bindable var viewModel: TodayViewModel
    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            Form {
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
            }
            .navigationTitle(TodayLocalization.Today.Edit.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.cancelEditingToday()
                    } label: {
                        Text(TodayLocalization.Common.cancel)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.saveEditedToday(modelContext: modelContext)
                    } label: {
                        Text(TodayLocalization.Common.save)
                    }
                }
            }
        }
    }
}

private struct TodayCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
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

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Self.cardBackground, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TodayValueRow: View {
    let title: LocalizedStringKey
    let value: String?
    let systemImage: String
    var showsEditIndicator = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                valueText
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.trailing)

                if showsEditIndicator {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .font(.body)
    }

    @ViewBuilder
    private var valueText: some View {
        if let value {
            Text(value)
        } else {
            Text(TodayLocalization.Common.notSet)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: WorkDay.self, inMemory: true)
}
