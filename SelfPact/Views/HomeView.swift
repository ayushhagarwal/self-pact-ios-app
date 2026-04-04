import SwiftUI

enum FilterType: String, CaseIterable {
    case all = "All"
    case sealed = "Locked"
    case draft = "Drafts"
    case completed = "Completed"
}

struct HomeView: View {
    @EnvironmentObject var pactStore: PactStore
    @State private var activeFilter: FilterType = .all
    @State private var showCreatePact = false
    @State private var navigationPath = NavigationPath()
    @State private var revealPactId: String?
    @State private var fabScale: CGFloat = 1
    
    private var filteredPacts: [Pact] {
        switch activeFilter {
        case .all: return pactStore.pacts
        case .sealed: return pactStore.sealedPacts
        case .draft: return pactStore.draftPacts
        case .completed: return pactStore.completedPacts
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header section
                    headerSection
                    
                    // Reveal banner
                    if !pactStore.revealablePacts.isEmpty {
                        revealBanner
                    }
                    
                    // Filter row
                    filterRow
                    
                    // Pact list
                    if filteredPacts.isEmpty && !pactStore.isLoading {
                        emptyState
                    } else {
                        pactList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .refreshable {
                // Refresh logic
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fabButton
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .navigationDestination(for: String.self) { pactId in
            PactDetailView(pactId: pactId)
        }
        .sheet(isPresented: $showCreatePact) {
            CreatePactView()
        }
        .fullScreenCover(item: $revealPactId) { id in
            RevealView(pactId: id)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("GoalLock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.4)

                Text("Your Goals")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.4)
            }
            
            Spacer()
            
            // Credit chip
            HStack(spacing: 5) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.accent)
                
                Text("\(pactStore.userData.creditCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.accentGlow)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.accentLight.opacity(0.6), lineWidth: 1)
            )
        }
        .padding(.top, 12)
        .padding(.bottom, 18)
    }
    
    // MARK: - Reveal Banner
    
    private var revealBanner: some View {
        Button {
            if let firstPact = pactStore.revealablePacts.first {
                revealPactId = firstPact.id
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGlowStrong)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accent)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(pactStore.revealablePacts.count == 1 ? "1 goal ready to review" : "\(pactStore.revealablePacts.count) goals ready to review")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.1)
                    
                    Text("Tap to review")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.accentGlowStrong)
                        .frame(width: 28, height: 28)
                    
                    Text("→")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(14)
            .background(AppColors.backgroundElevated)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 18)
    }
    
    // MARK: - Filter Row
    
    private var filterRow: some View {
        HStack(spacing: 8) {
            ForEach(FilterType.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(activeFilter == filter ? AppColors.accent : AppColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(activeFilter == filter ? AppColors.accentGlowStrong : AppColors.backgroundElevated)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(activeFilter == filter ? AppColors.accentLight.opacity(0.7) : AppColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.bottom, 18)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.backgroundElevated)
                    .frame(width: 88, height: 88)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.surface)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "shield")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(.bottom, 24)
            
            Text("No goals yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.3)
                .padding(.bottom, 8)
            
            Text("Create and lock your first goal")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 28)
            
            Button {
                showCreatePact = true
            } label: {
                Text("Create a Goal")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(-0.1)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppColors.accentStrong)
                    .cornerRadius(16)
                    .shadow(color: AppColors.accent.opacity(0.12), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Pact List
    
    private var pactList: some View {
        LazyVStack(spacing: 14) {
            ForEach(filteredPacts) { pact in
                NavigationLink(destination: PactDetailView(pactId: pact.id)) {
                    PactCard(pact: pact)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - FAB Button
    
    private var fabButton: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                fabScale = 0.88
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    fabScale = 1
                }
            }
            showCreatePact = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.accentStrong)
                    .frame(width: 54, height: 54)
                    .shadow(color: AppColors.accent.opacity(0.18), radius: 12, x: 0, y: 6)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(fabScale)
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
