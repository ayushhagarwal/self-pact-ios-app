import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var pactStore: PactStore
    @State private var showPurchase = false
    
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
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseView()
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
                            .fill(AppColors.backgroundElevated)
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
            .background(AppColors.backgroundElevated)
            .cornerRadius(16)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COMMITMENTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // Commitments available
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.accentGlow)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Commitments Available")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("\(pactStore.userData.creditCount) commitment\(pactStore.userData.creditCount != 1 ? "s" : "")")
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
                                .fill(AppColors.accentGlow)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.accent)
                        }
                        
                        Text("Get More Commitments")
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
            .background(AppColors.backgroundElevated)
            .cornerRadius(16)
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
                Link(destination: URL(string: "https://selfpact.ayushdev.com/privacy")!) {
                    settingsRow(icon: "lock.fill", title: "Privacy Policy")
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(AppColors.border)
                    .padding(.horizontal, 14)
                
                // Support and Feedback
                Link(destination: URL(string: "https://selfpact.ayushdev.com/support")!) {
                    settingsRow(icon: "envelope.fill", title: "Support and Feedback")
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.backgroundElevated)
            .cornerRadius(16)
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.backgroundElevated)
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
                        .foregroundColor(AppColors.accent)
                }
                
                Spacer()
            }
            .padding(14)
        }
        .background(AppColors.backgroundElevated)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Views
    
    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.backgroundElevated)
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
