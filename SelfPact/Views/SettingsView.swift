import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var pactStore: PactStore
    @State private var showDisableBackupAlert = false
    @State private var showPurchase = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.5)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    
                    // Backup section
                    backupSection
                    
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
        .alert("Disable Backup?", isPresented: $showDisableBackupAlert) {
            Button("Keep Enabled", role: .cancel) { }
            Button("Disable", role: .destructive) {
                pactStore.toggleICloudSync(false)
            }
        } message: {
            Text("If backup is disabled, your data cannot be recovered if you change or reset your device.")
        }
    }
    
    // MARK: - Backup Section
    
    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BACKUP")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(pactStore.userData.iCloudSyncEnabled ? AppColors.indigoGlow : AppColors.surfaceHighlight)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: pactStore.userData.iCloudSyncEnabled ? "cloud.fill" : "cloud.slash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(pactStore.userData.iCloudSyncEnabled ? AppColors.indigo : AppColors.textTertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("iCloud Sync")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(pactStore.userData.iCloudSyncEnabled ? "Your pacts are backed up" : "Backup disabled")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { pactStore.userData.iCloudSyncEnabled },
                        set: { newValue in
                            if newValue {
                                pactStore.toggleICloudSync(true)
                            } else {
                                showDisableBackupAlert = true
                            }
                        }
                    ))
                    .tint(AppColors.indigo)
                }
                .padding(14)
                
                if !pactStore.userData.iCloudSyncEnabled {
                    VStack {
                        Text("Data not recoverable — enable backup to protect your pacts.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.error)
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.errorGlow)
                    .overlay(
                        Rectangle()
                            .fill(AppColors.error.opacity(0.15))
                            .frame(height: 1),
                        alignment: .top
                    )
                }
            }
            .background(AppColors.surface)
            .cornerRadius(14)
        }
        .padding(.bottom, 24)
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
        .padding(.bottom, 24)
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
                Button {
                    if let url = URL(string: "https://example.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    settingsRow(icon: "lock.fill", title: "Privacy Policy")
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(AppColors.border)
                    .padding(.horizontal, 14)
                
                // Terms of Use
                Button {
                    if let url = URL(string: "https://example.com/terms") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    settingsRow(icon: "doc.text.fill", title: "Terms of Use")
                }
                .buttonStyle(.plain)
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
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("This app collects no data.")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
            }
            .padding(14)
        }
        .background(AppColors.surface)
        .cornerRadius(14)
    }
    
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
