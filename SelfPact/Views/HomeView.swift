import SwiftUI

private enum TodayCheckInOutcome: CaseIterable, Equatable {
    case didIt
    case partial
    case missed

    var title: String {
        switch self {
        case .didIt: return "Did it"
        case .partial: return "Partial"
        case .missed: return "Missed"
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
    case reflection(String)
}

struct HomeView: View {
    @EnvironmentObject var pactStore: PactStore

    @State private var showCreatePact = false
    @State private var revealPactId: String?
    @State private var selectedOutcomes: [String: TodayCheckInOutcome] = [:]
    @State private var nextActionDrafts: [String: String] = [:]
    @State private var reflectionNotes: [String: String] = [:]
    @State private var savedPactIDs: Set<String> = []
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

            statsRow(for: pact)
            weeklySummaryCard(for: pact)
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

                    Text(hasCheckedInToday(pact) ? "You can update it if the day changed." : "One tap is enough. Details can come after.")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if savedPactIDs.contains(pact.id) {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.accent)
                }
            }

            HStack(spacing: 8) {
                ForEach(TodayCheckInOutcome.allCases, id: \.self) { outcome in
                    checkInButton(outcome, pact: pact)
                }
            }

            if let selectedOutcome = selectedOutcomes[pact.id] {
                reflectionComposer(for: pact, outcome: selectedOutcome)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedOutcomes[pact.id])
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
                .focused($focusedField, equals: .reflection(pact.id))

            Button {
                saveTodayCheckIn(for: pact, outcome: outcome)
            } label: {
                Text(reflectionNote(for: pact).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Skip Note" : "Save Note")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accentStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
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

    private func statsRow(for pact: Pact) -> some View {
        HStack(spacing: 8) {
            TodayStatTile(
                icon: "calendar",
                label: "Days left",
                value: pact.status == .sealed && pact.isReady ? "Review" : "\(pact.daysRemaining)d"
            )

            TodayStatTile(
                icon: "flame",
                label: "Streak",
                value: "\(pactStore.currentStreak(for: pact))d"
            )

            TodayStatTile(
                icon: "clock",
                label: "Last",
                value: lastCheckInText(for: pact)
            )
        }
    }

    private func weeklySummaryCard(for pact: Pact) -> some View {
        let summary = weeklySummary(for: pact)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(summary.loggedDays)/\(summary.scheduledDays) due")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppColors.accentGlow)
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                WeeklySummaryMetric(label: "Did it", value: "\(summary.didIt)")
                WeeklySummaryMetric(label: "Partial", value: "\(summary.partial)")
                WeeklySummaryMetric(label: "Missed", value: "\(summary.missed)")
            }

            Text(summary.prompt)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(AppColors.backgroundElevated.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
        focusedField = .reflection(pact.id)

        pactStore.addTodayCheckIn(
            pactId: pact.id,
            progress: outcome.progress,
            note: nil,
            nextAction: nextActionDraft(for: pact)
        )

        rescheduleReminders(for: pact.id)
        syncNextActionDraft(for: pact)
        savedPactIDs.insert(pact.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            savedPactIDs.remove(pact.id)
        }
    }

    private func saveTodayCheckIn(for pact: Pact, outcome: TodayCheckInOutcome) {
        pactStore.addTodayCheckIn(
            pactId: pact.id,
            progress: outcome.progress,
            note: reflectionNote(for: pact),
            nextAction: nextActionDraft(for: pact)
        )

        rescheduleReminders(for: pact.id)
        resetCheckInComposer(for: pact.id)
        syncNextActionDraft(for: pact)
        focusedField = nil
        savedPactIDs.insert(pact.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            savedPactIDs.remove(pact.id)
        }
    }

    private func syncTodayDrafts() {
        for pact in todayPacts where nextActionDrafts[pact.id] == nil {
            syncNextActionDraft(for: pact)
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

    private func resetCheckInComposer(for pactId: String) {
        selectedOutcomes.removeValue(forKey: pactId)
        reflectionNotes[pactId] = ""
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

    private func lastCheckInText(for pact: Pact) -> String {
        guard let checkIn = pactStore.lastCheckIn(for: pact) else {
            return "None"
        }

        if Calendar.current.isDateInToday(checkIn.date) {
            return "Today"
        }

        return checkIn.date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func weeklySummary(for pact: Pact) -> WeeklySummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let pactStartDate = calendar.startOfDay(for: pact.sealTimestamp ?? pact.createdAt)
        let summaryStartDate = max(startDate, pactStartDate)
        let checkIns = pact.checkIns.filter {
            $0.date >= summaryStartDate && pactStore.isScheduledForCheckIn(pact, on: $0.date)
        }
        let didIt = checkIns.filter { $0.progress >= 100 }.count
        let partial = checkIns.filter { $0.progress > 0 && $0.progress < 100 }.count
        let missed = checkIns.filter { $0.progress == 0 }.count
        let loggedDays = Set(checkIns.map { calendar.startOfDay(for: $0.date) }).count
        let scheduledDays = (0..<7).reduce(into: 0) { count, dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return }
            if date >= summaryStartDate && pactStore.isScheduledForCheckIn(pact, on: date) {
                count += 1
            }
        }

        let prompt: String
        if loggedDays == 0 {
            prompt = "Start with one check-in today. The habit loop should feel light."
        } else if missed > didIt {
            prompt = "Look for the smallest version of this action that still counts tomorrow."
        } else {
            prompt = "Notice what made the good days easier, then repeat that setup tomorrow."
        }

        return WeeklySummary(
            didIt: didIt,
            partial: partial,
            missed: missed,
            loggedDays: loggedDays,
            scheduledDays: max(scheduledDays, 1),
            prompt: prompt
        )
    }
}

private struct WeeklySummary {
    let didIt: Int
    let partial: Int
    let missed: Int
    let loggedDays: Int
    let scheduledDays: Int
    let prompt: String
}

private struct WeeklySummaryMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TodayStatTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
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
