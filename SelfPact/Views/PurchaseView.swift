import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pactStore: PactStore
    @EnvironmentObject private var storeKit: StoreKitManager

    var onPurchaseComplete: (() -> Void)? = nil

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        hero
                        benefits
                        purchaseSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(AppColors.backgroundElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Close")
                }
            }
            .task {
                await storeKit.loadProduct()
            }
        }
        .alert("Purchase unavailable", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var hero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppColors.accentGlow)
                    .frame(width: 92, height: 92)

                Image(systemName: "infinity")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(AppColors.accent)
            }

            VStack(spacing: 10) {
                Text("GoalLock Plus")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-1)

                Text("Keep making promises to yourself without paying for every new pact.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !pactStore.hasLifetimeAccess {
                Text("Three locked pacts are included free")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.accentGlow)
                    .clipShape(Capsule())
            }
        }
    }

    private var benefits: some View {
        VStack(spacing: 0) {
            benefitRow(
                icon: "lock.open.fill",
                title: "Unlimited locked pacts",
                detail: "Start the next commitment whenever you are ready."
            )

            Divider()
                .background(AppColors.border)
                .padding(.leading, 54)

            benefitRow(
                icon: "clock.arrow.circlepath",
                title: "Keep your permanent history",
                detail: "Completed and broken pacts remain part of your record."
            )

            Divider()
                .background(AppColors.border)
                .padding(.leading, 54)

            benefitRow(
                icon: "creditcard.fill",
                title: "Pay once",
                detail: "Lifetime access with no subscription or recurring charge."
            )
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func benefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: 40, height: 40)
                .background(AppColors.accentGlow)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await purchase() }
            } label: {
                HStack(spacing: 10) {
                    if storeKit.purchaseInProgress {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(purchaseButtonTitle)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(AppColors.accentStrong)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(storeKit.purchaseInProgress || storeKit.restoreInProgress || storeKit.isLoadingProduct || pactStore.hasLifetimeAccess)
            .opacity(pactStore.hasLifetimeAccess ? 0.65 : 1)

            Button {
                Task { await restore() }
            } label: {
                HStack(spacing: 7) {
                    if storeKit.restoreInProgress {
                        ProgressView()
                            .controlSize(.small)
                            .tint(AppColors.textSecondary)
                    }

                    Text(storeKit.restoreInProgress ? "Restoring…" : "Restore Purchase")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(storeKit.purchaseInProgress || storeKit.restoreInProgress)

            Text("One-time purchase · No subscription")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textMuted)
        }
    }

    private var purchaseButtonTitle: String {
        if pactStore.hasLifetimeAccess {
            return "GoalLock Plus is active"
        }
        if storeKit.isLoadingProduct {
            return "Loading…"
        }
        if let product = storeKit.lifetimeProduct {
            return "Unlock forever · \(product.displayPrice)"
        }
        return "Try loading GoalLock Plus"
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented { errorMessage = nil }
            }
        )
    }

    private func purchase() async {
        let success = await storeKit.purchaseLifetime()
        if success {
            onPurchaseComplete?()
            dismiss()
        } else if let purchaseError = storeKit.purchaseError {
            errorMessage = purchaseError
        }
    }

    private func restore() async {
        let success = await storeKit.restorePurchases()
        if success {
            onPurchaseComplete?()
            dismiss()
        } else if let purchaseError = storeKit.purchaseError {
            errorMessage = purchaseError
        }
    }
}

#Preview {
    PurchaseView()
        .environmentObject(PactStore())
        .environmentObject(StoreKitManager())
}
