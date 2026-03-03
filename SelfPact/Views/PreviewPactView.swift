import SwiftUI

struct PreviewPactView: View {
    let pactId: String
    var onDismissAll: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    
    @State private var showSealAnimation = false
    @State private var isSealingInProgress = false
    
    private var pact: Pact? {
        pactStore.getPact(id: pactId)
    }
    
    private var hasCredits: Bool {
        pactStore.userData.creditCount > 0
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
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showSealAnimation)
    }
    
    // MARK: - Main Content
    
    private func mainContent(pact: Pact) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Contract card
                contractCard(pact: pact)
                
                // Warning box
                warningBox
                
                // Actions
                actionButtons
            }
            .padding(20)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Contract Card
    
    private func contractCard(pact: Pact) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppColors.borderLight)
                    .frame(height: 1)
                
                Text("COMMITMENT CONTRACT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textMuted)
                    .tracking(2.5)
                
                Rectangle()
                    .fill(AppColors.borderLight)
                    .frame(height: 1)
            }
            .padding(.bottom, 22)
            
            // Title
            Text(pact.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.3)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            
            // Purpose
            if let why = pact.why, !why.isEmpty {
                sectionView(label: "Purpose", content: why)
            }
            
            // Measurable Target
            if let target = pact.measurableTarget, !target.isEmpty {
                sectionView(label: "Measurable Target", content: target)
            }
            
            // Target Date
            sectionView(
                label: "Target Date",
                content: pact.targetDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
            )
            
            // Footer
            HStack(spacing: 6) {
                Image(systemName: "shield")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textMuted)
                
                Text("Drafted on \(pact.createdAt.formatted(.dateTime.month(.wide).day().year()))")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .overlay(
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1),
                alignment: .top
            )
        }
        .padding(26)
        .background(AppColors.surface)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .padding(.bottom, 18)
    }
    
    private func sectionView(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.6)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 16)
    }
    
    // MARK: - Warning Box
    
    private var warningBox: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "D4983F").opacity(0.12))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.warning)
            }
            .padding(.top, 1)
            
            Text("Once sealed, this pact cannot be edited. The title, purpose, and target date become immutable.")
                .font(.system(size: 13))
                .foregroundColor(AppColors.warning)
                .lineSpacing(4)
        }
        .padding(14)
        .background(Color(hex: "D4983F").opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "D4983F").opacity(0.12), lineWidth: 1)
        )
        .padding(.bottom, 24)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Edit button
            Button {
                dismiss()
            } label: {
                Text("Edit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.surface)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
            
            // Seal button
            Button {
                handleSeal()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    
                    Text(hasCredits
                         ? "Seal My Pact\(pactStore.userData.creditCount == 1 ? " (1 Free Seal)" : "")"
                         : "Purchase a Seal")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(-0.2)
                }
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.gold)
                .cornerRadius(14)
                .shadow(color: AppColors.gold.opacity(0.25), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isSealingInProgress || (!hasCredits))
            .opacity(isSealingInProgress ? 0.6 : 1.0)
        }
    }
    
    // MARK: - Already Sealed View
    
    private var alreadySealedView: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppColors.goldGlow)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 26))
                    .foregroundColor(AppColors.gold)
            }
            
            Text("This pact is already sealed.")
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
                    .background(AppColors.surface)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }
    
    // MARK: - Not Found View
    
    private var notFoundView: some View {
        Text("Pact not found.")
            .font(.system(size: 16))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    // SECURITY: Double-tap protection to prevent negative credits
    private func handleSeal() {
        guard !isSealingInProgress else { return }
        guard hasCredits else {
            // Navigate to purchase
            return
        }
        
        isSealingInProgress = true
        
        let success = pactStore.sealPact(id: pactId)
        if success {
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
    }
}
