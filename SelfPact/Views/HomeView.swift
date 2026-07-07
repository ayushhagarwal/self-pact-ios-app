import SwiftUI

private enum TodayCheckInOutcome: CaseIterable, Equatable {
    case didIt
    case partial
    case missed

    var title: String {
        switch self {
        case .didIt: return "Did it"
        case .partial: return "Made progress"
        case .missed: return "Not today"
        }
    }

    var systemImage: String {
        switch self {
        case .didIt: return "checkmark"
        case .partial: return "circle.lefthalf.filled"
        case .missed: return "xmark"
        }
    }

    var progress: Int {
        switch self {
        case .didIt: return 100
        case .partial: return 50
        case .missed: return 0
        }
    }

    var tint: Color {
        switch self {
        case .didIt: return AppColors.success
        case .partial: return AppColors.warning
        case .missed: return AppColors.error
        }
    }
}

private enum TodayField: Hashable {
    case nextAction(String)
}

struct HomeView: View {
    @EnvironmentObject var pactStore: PactStore

    @State private var showCreatePact = false
    @State private var revealPactId: String?
    @State private var selectedOutcomes: [String: TodayCheckInOutcome] = [:]
    @State private var nextActionDrafts: [String: String] = [:]
    @State private var reflectionNotes: [String: String] = [:]
    @State private var noteComposerPactIDs: Set<String> = []
    @FocusState private var focusedField: TodayField?

    private var todayPacts: [Pact] {
        pactStore.todayPacts
    }

    private var todayPactIDs: [String] {
        todayPacts.map(\.id)
    }

    private var hasActiveGoals: Bool {
        !pactStore.sealedPacts.isEmpty || !pactStore.draftPacts.isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection

                    if !todayPacts.isEmpty {
                        if todayPacts.count > 1 {
                            Label("\(todayPacts.count) commitments are due today", systemImage: "checklist")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.commitment)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppColors.commitmentGlow)
                                .clipShape(Capsule())
                        }

                        LazyVStack(spacing: 16) {
                            ForEach(todayPacts) { pact in
                                todaySection(for: pact)
                            }
                        }
                    } else {
                        emptyTodayState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showCreatePact) {
            CreatePactView()
        }
        .fullScreenCover(item: $revealPactId) { id in
            RevealView(pactId: id)
        }
        .onAppear {
            syncTodayDrafts()
        }
        .onChange(of: todayPactIDs) { _, _ in
            syncTodayDrafts()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Today")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.5)

                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button {
                showCreatePact = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentStrong)
                        .frame(width: 44, height: 44)

                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create a goal")
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
    }

    // MARK: - Today

    private func todaySection(for pact: Pact) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            activeGoalHeader(for: pact)
            nextActionCard(for: pact)

            if pact.status == .sealed && pact.isReady {
                reviewReadyCard(for: pact)
            } else {
                checkInCard(for: pact)
            }

            weeklyProgressLink(for: pact)
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 5)
    }

    private func activeGoalHeader(for pact: Pact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(pact.status == .sealed ? "Active locked goal" : "Trial goal", systemImage: pact.status == .sealed ? "lock.fill" : "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(pact.status == .sealed ? AppColors.commitment : AppColors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(pact.status == .sealed ? AppColors.commitmentGlow : AppColors.accentGlow)
                    .clipShape(Capsule())

                Spacer()

                NavigationLink(destination: PactDetailView(pactId: pact.id)) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open goal details")
            }

            Text(pact.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.35)
                .lineSpacing(3)

            if let target = pact.measurableTarget, !target.isEmpty {
                Text(target)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(4)
            }
        }
    }

    private func nextActionCard(for pact: Pact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What is the next small action today?")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            TextField("e.g., Walk 20 minutes before lunch", text: nextActionBinding(for: pact), axis: .vertical)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1...3)
                .padding(14)
                .background(AppColors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(focusedField == .nextAction(pact.id) ? AppColors.accentLight : AppColors.border, lineWidth: 1)
                )
                .focused($focusedField, equals: .nextAction(pact.id))

            if nextActionHasChanges(for: pact) {
                HStack {
                    Spacer()

                    Button {
                        pactStore.updateNextAction(pactId: pact.id, nextAction: nextActionDraft(for: pact))
                        rescheduleReminders(for: pact.id)
                        focusedField = nil
                    } label: {
                        Text("Save action")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.accentGlow)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(AppColors.backgroundElevated.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func checkInCard(for pact: Pact) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(hasCheckedInToday(pact) ? "Today is logged" : "Log today")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text(hasCheckedInToday(pact) ? "Tap another response if your day changed." : "Choose once and you’re done.")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }

            }

            HStack(spacing: 8) {
                ForEach(TodayCheckInOutcome.allCases, id: \.self) { outcome in
                    checkInButton(outcome, pact: pact)
                }
            }

            if let selectedOutcome = selectedOutcomes[pact.id] {
                loggedConfirmation(for: pact, outcome: selectedOutcome)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedOutcomes[pact.id])
        .animation(.easeInOut(duration: 0.2), value: noteComposerPactIDs.contains(pact.id))
    }

    private func loggedConfirmation(for pact: Pact, outcome: TodayCheckInOutcome) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.accent)

                Text("Check-in logged")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                if !noteComposerPactIDs.contains(pact.id) {
                    Button("Add note") {
                        noteComposerPactIDs.insert(pact.id)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                    .buttonStyle(.plain)
                }
            }

            if noteComposerPactIDs.contains(pact.id) {
                reflectionComposer(for: pact, outcome: outcome)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(AppColors.accentGlow.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func checkInButton(_ outcome: TodayCheckInOutcome, pact: Pact) -> some View {
        Button {
            logTodayCheckIn(for: pact, outcome: outcome)
        } label: {
            VStack(spacing: 7) {
                Image(systemName: outcome.systemImage)
                    .font(.system(size: 15, weight: .bold))

                Text(outcome.title)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(selectedOutcomes[pact.id] == outcome ? .white : outcome.tint)
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(selectedOutcomes[pact.id] == outcome ? outcome.tint : AppColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedOutcomes[pact.id] == outcome ? outcome.tint.opacity(0.25) : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func reflectionComposer(for pact: Pact, outcome: TodayCheckInOutcome) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What would make tomorrow easier?")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            TextField("Optional note", text: reflectionBinding(for: pact), axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2...4)
                .padding(14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            Button {
                saveTodayCheckIn(for: pact, outcome: outcome)
            } label: {
                Text("Save note")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accentStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(reflectionNote(for: pact).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(reflectionNote(for: pact).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(14)
        .background(AppColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func reviewReadyCard(for pact: Pact) -> some View {
        Button {
            revealPactId = pact.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.review)
                    .frame(width: 40, height: 40)
                    .background(AppColors.reviewGlow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Ready for review")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("This goal has reached its target date.")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.review)
            }
            .padding(14)
            .background(AppColors.reviewGlow.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func weeklyProgressLink(for pact: Pact) -> some View {
        let progress = weeklyProgress(for: pact)

        return NavigationLink(destination: PactDetailView(pactId: pact.id)) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.accent)

                Text("\(progress.logged) of \(progress.scheduled) check-ins this week")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(progress.logged) of \(progress.scheduled) check-ins this week. Open goal details.")
    }

    // MARK: - Empty

    private var emptyTodayState: some View {
        VStack(spacing: 18) {
            Image(systemName: hasActiveGoals ? "checkmark.circle" : "target")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: 70, height: 70)
                .background(AppColors.accentGlow)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 8) {
                Text(hasActiveGoals ? "Nothing is due today" : "Choose one goal for today")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.3)
                    .multilineTextAlignment(.center)

                Text(hasActiveGoals ? "Your commitments are still active. The next one will return on its scheduled check-in day." : "Start with one clear commitment and a small action you can do today.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            if !hasActiveGoals {
                Button {
                    showCreatePact = true
                } label: {
                    Text("Create a Goal")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 13)
                        .background(AppColors.accentStrong)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func logTodayCheckIn(for pact: Pact, outcome: TodayCheckInOutcome) {
        selectedOutcomes[pact.id] = outcome
        reflectionNotes[pact.id] = ""
        noteComposerPactIDs.remove(pact.id)
        focusedField = nil

        pactStore.addTodayCheckIn(
            pactId: pact.id,
            progress: outcome.progress,
            note: nil,
            nextAction: nextActionDraft(for: pact)
        )

        rescheduleReminders(for: pact.id)
        syncNextActionDraft(for: pact)
    }

    private func saveTodayCheckIn(for pact: Pact, outcome: TodayCheckInOutcome) {
        pactStore.addTodayCheckIn(
            pactId: pact.id,
            progress: outcome.progress,
            note: reflectionNote(for: pact),
            nextAction: nextActionDraft(for: pact)
        )

        rescheduleReminders(for: pact.id)
        noteComposerPactIDs.remove(pact.id)
        reflectionNotes[pact.id] = ""
        syncNextActionDraft(for: pact)
        focusedField = nil
    }

    private func syncTodayDrafts() {
        for pact in todayPacts {
            if nextActionDrafts[pact.id] == nil {
                syncNextActionDraft(for: pact)
            }

            if selectedOutcomes[pact.id] == nil,
               let checkIn = pact.checkIns.last(where: { Calendar.current.isDateInToday($0.date) }) {
                selectedOutcomes[pact.id] = outcome(for: checkIn.progress)
            }
        }
    }

    private func syncNextActionDraft(for pact: Pact) {
        nextActionDrafts[pact.id] = pact.nextAction ?? ""
    }

    private func rescheduleReminders(for pactId: String) {
        guard let pact = pactStore.getPact(id: pactId) else { return }

        Task {
            await ReminderManager.scheduleReminder(for: pact)
        }
    }

    private func nextActionHasChanges(for pact: Pact) -> Bool {
        nextActionDraft(for: pact).trimmingCharacters(in: .whitespacesAndNewlines) != (pact.nextAction ?? "")
    }

    private func nextActionDraft(for pact: Pact) -> String {
        nextActionDrafts[pact.id] ?? pact.nextAction ?? ""
    }

    private func reflectionNote(for pact: Pact) -> String {
        reflectionNotes[pact.id] ?? ""
    }

    private func nextActionBinding(for pact: Pact) -> Binding<String> {
        Binding(
            get: { nextActionDraft(for: pact) },
            set: { nextActionDrafts[pact.id] = $0 }
        )
    }

    private func reflectionBinding(for pact: Pact) -> Binding<String> {
        Binding(
            get: { reflectionNote(for: pact) },
            set: { reflectionNotes[pact.id] = $0 }
        )
    }

    private func hasCheckedInToday(_ pact: Pact) -> Bool {
        pact.checkIns.contains {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }
    }

    private func outcome(for progress: Int) -> TodayCheckInOutcome {
        if progress >= 100 { return .didIt }
        if progress > 0 { return .partial }
        return .missed
    }

    private func weeklyProgress(for pact: Pact) -> WeeklyProgress {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let pactStart = calendar.startOfDay(for: pact.sealTimestamp ?? pact.createdAt)
        let start = max(weekStart, pactStart)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

        var scheduledDays = 0
        var date = start
        while date <= today {
            if pactStore.isScheduledForCheckIn(pact, on: date) {
                scheduledDays += 1
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? today.addingTimeInterval(1)
        }

        let loggedDays = Set(
            pact.checkIns
                .filter { $0.date >= start && $0.date < tomorrow }
                .map { calendar.startOfDay(for: $0.date) }
        ).count

        return WeeklyProgress(logged: loggedDays, scheduled: max(scheduledDays, loggedDays))
    }
}

private struct WeeklyProgress {
    let logged: Int
    let scheduled: Int
}

// Extension to make String identifiable for fullScreenCover
extension String: @retroactive Identifiable {
    public var id: String { self }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(PactStore())
    }
}
