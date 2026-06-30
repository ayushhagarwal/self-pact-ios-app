import SwiftUI

struct PreviewPactView: View {
    let pactId: String
    var onDismissAll: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    
    @State private var showSealAnimation = false
    @State private var isSealingInProgress = false
    @State private var showPurchase = false
    
    private var pact: Pact? {
        pactStore.getPact(id: pactId)
    }
    
    private var needsPlusUpgrade: Bool {
        !pactStore.canSealAnotherPact
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if let pact = pact {
                if pact.isSealed {
                    alreadySealedView
                } else {
                    mainContent(pact: pact)
                }
            } else {
                notFoundView
            }
            
            // Seal animation overlay
            SealAnimation(visible: showSealAnimation) {
                showSealAnimation = false
                // Dismiss all the way back to home
                if let onDismissAll = onDismissAll {
                    onDismissAll()
                } else {
                    dismiss()
                }
            }
        }
        .navigationTitle("Lock Goal")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showSealAnimation)
        .sheet(isPresented: $showPurchase) {
            PurchaseView {
                handleSeal()
            }
        }
    }
    
    // MARK: - Main Content
    
    private func mainContent(pact: Pact) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                contractCard(pact: pact)
                actionButtons
            }
            .padding(24)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Contract Card
    
    private func contractCard(pact: Pact) -> some View {
        VStack(spacing: 0) {
            // Title
            Text(pact.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.2)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)
            
            // Purpose
            if let why = pact.why, !why.isEmpty {
                Text(why)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
            }

            // Measurable Target
            if let target = pact.measurableTarget, !target.isEmpty {
                Text(target)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
            }

            VStack(spacing: 6) {
                Text("Target date")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.4)

                Text(pact.targetDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.top, 4)
        }
        .padding(28)
        .background(AppColors.surface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Edit button
            Button {
                dismiss()
            } label: {
                Text("Edit Goal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.backgroundElevated)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            // Seal button
            Button {
                if needsPlusUpgrade {
                    showPurchase = true
                } else {
                    handleSeal()
                }
            } label: {
                Text(needsPlusUpgrade ? "Unlock GoalLock Plus" : "Lock Goal")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(-0.2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppColors.accentStrong)
                    .cornerRadius(16)
                    .shadow(color: AppColors.accent.opacity(0.16), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isSealingInProgress)
            .opacity(isSealingInProgress ? 0.6 : 1.0)

            if needsPlusUpgrade {
                Text("You have used your three included locked pacts.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            } else if !pactStore.hasLifetimeAccess {
                Text(includedPactMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.accent)
            }

            Text("This cannot be edited after locking")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 4)
        }
    }
    
    // MARK: - Already Sealed View
    
    private var alreadySealedView: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppColors.accentGlow)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 26))
                    .foregroundColor(AppColors.accent)
            }
            
            Text("This goal is already locked.")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                dismiss()
            } label: {
                Text("Go Back")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.backgroundElevated)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }
    
    // MARK: - Not Found View
    
    private var notFoundView: some View {
        Text("Goal not found.")
            .font(.system(size: 16))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    private var includedPactMessage: String {
        if pactStore.freePactsRemaining == 1 {
            return "This is your final included locked pact."
        }
        return "\(pactStore.freePactsRemaining) included locked pacts remain."
    }

    private func handleSeal() {
        guard !isSealingInProgress else { return }
        guard !needsPlusUpgrade else { showPurchase = true; return }
        
        isSealingInProgress = true
        
        let success = pactStore.sealPact(id: pactId)
        if success {
            if let pact = pactStore.getPact(id: pactId) {
                Task {
                    await ReminderManager.scheduleReminder(for: pact)
                }
            }
            showSealAnimation = true
            // isSealingInProgress will reset when animation completes and view dismisses
        } else {
            isSealingInProgress = false
        }
    }
}

#Preview {
    NavigationStack {
        PreviewPactView(pactId: "test")
            .environmentObject(PactStore())
            .environmentObject(StoreKitManager())
    }
}
