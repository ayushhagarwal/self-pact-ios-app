import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var pactStore: PactStore
    @State private var showPurchase = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showResetAlert = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.5)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    
                    // Storage section
                    storageSection
                    
                    // Credits section
                    creditsSection
                    
                    // Legal section
                    legalSection
                    
                    // Info section
                    infoSection
                    
                    #if DEBUG
                    // Debug section (only in debug builds)
                    debugSection
                    #endif
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseView()
        }
        .alert("Reset Onboarding?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                hasCompletedOnboarding = false
            }
        } message: {
            Text("The onboarding flow will show again on next app launch.")
        }
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DATA STORAGE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.surfaceHighlight)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local Storage Only")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Your commitments are stored privately on this device.\nSync across devices is not available.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
            .background(AppColors.surface)
            .cornerRadius(14)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREDITS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // Seals available
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.goldGlow)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.gold)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Seals Available")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("\(pactStore.userData.creditCount) credit\(pactStore.userData.creditCount != 1 ? "s" : "")")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                }
                .padding(14)
                
                Divider()
                    .background(AppColors.border)
                    .padding(.horizontal, 14)
                
                // Buy more
                Button {
                    showPurchase = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.goldGlow)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.gold)
                        }
                        
                        Text("Buy More Seals")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.surface)
            .cornerRadius(14)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LEGAL")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // Privacy Policy
                // TODO: Replace with actual privacy policy URL before App Store submission
                Button {
                    // Disabled until real URL is provided
                } label: {
                    settingsRow(icon: "lock.fill", title: "Privacy Policy")
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.5)
                
                Divider()
                    .background(AppColors.border)
                    .padding(.horizontal, 14)
                
                // Support and Feedback
                // TODO: Replace with actual support URL before App Store submission
                Button {
                    // Disabled until real URL is provided
                } label: {
                    settingsRow(icon: "envelope.fill", title: "Support and Feedback")
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.5)
            }
            .background(AppColors.surface)
            .cornerRadius(14)
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.surfaceHighlight)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("SelfPact")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("This app collects no data.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.gold)
                }
                
                Spacer()
            }
            .padding(14)
        }
        .background(AppColors.surface)
        .cornerRadius(14)
    }
    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEBUG")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Button {
                    showResetAlert = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.surfaceHighlight)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        
                        Text("Reset Onboarding")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(14)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppColors.surface)
            .cornerRadius(14)
        }
        .padding(.bottom, 20)
    }
    #endif
    
    // MARK: - Helper Views
    
    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceHighlight)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textMuted)
        }
        .padding(14)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PactStore())
}
