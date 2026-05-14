import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var pactStore: PactStore

    @State private var showCreatePact = false
    @State private var showTrialGoals = false
    @State private var showCompletedArchive = false

    private var lockedGoals: [Pact] {
        pactStore.sealedPacts
            .sorted { $0.targetDate < $1.targetDate }
    }

    private var trialGoals: [Pact] {
        pactStore.draftPacts
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var completedGoals: [Pact] {
        pactStore.completedPacts
            .sorted { ($0.sealTimestamp ?? $0.createdAt) > ($1.sealTimestamp ?? $1.createdAt) }
    }

    private var hasAnyGoals: Bool {
        !lockedGoals.isEmpty || !trialGoals.isEmpty || !completedGoals.isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection

                    if hasAnyGoals {
                        if !lockedGoals.isEmpty {
                            goalSection(
                                title: "Locked goals",
                                count: lockedGoals.count,
                                pacts: lockedGoals
                            )
                        }

                        if !trialGoals.isEmpty {
                            tuckedGoalsSection(
                                title: "Trial goals",
                                count: trialGoals.count,
                                isExpanded: $showTrialGoals,
                                pacts: trialGoals
                            )
                        }

                        if !completedGoals.isEmpty {
                            tuckedGoalsSection(
                                title: "Completed archive",
                                count: completedGoals.count,
                                isExpanded: $showCompletedArchive,
                                pacts: completedGoals
                            )
                        }
                    } else {
                        emptyGoalsState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreatePact) {
            CreatePactView()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Goals")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.5)

                Text("Manage commitments and past reviews")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button {
                showCreatePact = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColors.accentStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create a goal")
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
    }

    private func goalSection(title: String, count: Int, pacts: [Pact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: title, count: count)

            LazyVStack(spacing: 12) {
                ForEach(pacts) { pact in
                    goalLink(for: pact)
                }
            }
        }
    }

    private func tuckedGoalsSection(
        title: String,
        count: Int,
        isExpanded: Binding<Bool>,
        pacts: [Pact]
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            LazyVStack(spacing: 12) {
                ForEach(pacts) { pact in
                    goalLink(for: pact)
                }
            }
            .padding(.top, 12)
        } label: {
            sectionHeader(title: title, count: count)
        }
        .padding(14)
        .background(AppColors.surface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .tint(AppColors.accent)
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(AppColors.backgroundElevated)
                .clipShape(Capsule())
        }
    }

    private func goalLink(for pact: Pact) -> some View {
        NavigationLink(destination: PactDetailView(pactId: pact.id)) {
            PactCard(pact: pact)
        }
        .buttonStyle(.plain)
    }

    private var emptyGoalsState: some View {
        VStack(spacing: 18) {
            Image(systemName: "target")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: 70, height: 70)
                .background(AppColors.accentGlow)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 8) {
                Text("Create your first goal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.3)

                Text("Start free, build a daily rhythm, then lock a goal when the commitment feels worth it.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

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
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        GoalsView()
            .environmentObject(PactStore())
    }
}
