import SwiftUI

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    @EnvironmentObject var storeKit: StoreKitManager
    
    var onPurchaseComplete: (() -> Void)? = nil
    
    @State private var selectedProduct: IAPProductModel?
    @State private var showSuccessAlert = false
    @State private var showRestoreSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoadingProducts = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                if isLoadingProducts {
                    ProgressView("Loading products...")
                        .tint(AppColors.accent)
                        .foregroundColor(AppColors.textSecondary)
                } else if storeKit.products.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.accent)
                        
                        Text("No Products Available")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Enable StoreKit Configuration in Xcode scheme for simulator testing.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header section
                            headerSection
                            
                            // Products
                            productsSection
                            
                            // Restore button
                            restoreButton
                            
                            // Disclaimer
                            disclaimer
                        }
                        .padding(22)
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
            }
            .task {
                await loadProducts()
            }
        }
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
                onPurchaseComplete?()
            }
        } message: {
            if let product = selectedProduct {
                Text("\(product.credits) Lock Mode credit\(product.credits > 1 ? "s" : "") added to your account.")
            }
        }
        .alert("Restored!", isPresented: $showRestoreSuccessAlert) {
            Button("OK") {
                dismiss()
                onPurchaseComplete?()
            }
        } message: {
            Text("\(storeKit.restoredCredits) Lock Mode credit\(storeKit.restoredCredits > 1 ? "s" : "") restored to your account.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Load Products
    
    private func loadProducts() async {
        await storeKit.loadProducts()
        isLoadingProducts = false
    }
    
    // MARK: - Purchase Product
    
    private func purchaseProduct(_ product: IAPProductModel) async {
        selectedProduct = product
        
        let success = await storeKit.purchase(product)
        
        if success {
            showSuccessAlert = true
        } else if let error = storeKit.purchaseError {
            errorMessage = error
            showErrorAlert = true
        }
    }
    
    // MARK: - Restore Purchases
    
    private func restorePurchases() async {
        await storeKit.restorePurchases()
        
        if storeKit.restoreSuccess {
            showRestoreSuccessAlert = true
        } else if let error = storeKit.purchaseError {
            errorMessage = error
            showErrorAlert = true
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.backgroundElevated)
                    .frame(width: 34, height: 34)
                
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.accentGlow)
                    .frame(width: 80, height: 80)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGlowStrong)
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26))
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(.bottom, 24)
            
            Text("Unlock\nLock Mode")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-1.2)
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .padding(.bottom, 12)
            
            Text("Your first lock is free.\nUse Lock Mode when you want stronger commitment.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .tracking(-0.1)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            
            HStack(spacing: 6) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.accent)
                
                Text("\(pactStore.userData.creditCount) Lock Mode credit\(pactStore.userData.creditCount != 1 ? "s" : "") available")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.backgroundElevated)
            .cornerRadius(16)
        }
        .padding(.bottom, 36)
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        VStack(spacing: 14) {
            // Products are already sorted by featured status
            ForEach(storeKit.products) { product in
                productCard(product: product)
                
                // Add "Most people choose 5" text after 5-pack
                if product.featured {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.accent.opacity(0.7))
                        
                        Text("For people locking multiple goals")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                            .italic()
                    }
                    .padding(.bottom, 6)
                }
            }
        }
        .padding(.bottom, 28)
    }
    
    private func productCard(product: IAPProductModel) -> some View {
        Button {
            Task {
                await purchaseProduct(product)
            }
        } label: {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.4)
                    
                    Text(product.displayDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(-0.1)
                }
                
                Spacer()
                
                if storeKit.purchaseInProgress && selectedProduct?.id == product.id {
                    ProgressView()
                        .tint(product.featured ? AppColors.accent : AppColors.textPrimary)
                } else {
                    Text(product.formattedPrice)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(product.featured ? AppColors.accent : AppColors.textPrimary)
                        .tracking(-1.0)
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(product.featured ? AppColors.accentGlow : AppColors.backgroundElevated)
                    .shadow(color: product.featured ? AppColors.accent.opacity(0.12) : Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(product.featured ? AppColors.accent.opacity(0.4) : AppColors.border, lineWidth: product.featured ? 2 : 1)
            )
            .overlay(
                // Badge
                Group {
                    if let badge = product.badge {
                        HStack(spacing: 3) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9))
                            
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.3)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.accent)
                        .clipShape(BadgeShape())
                    }
                },
                alignment: .topTrailing
            )
            .scaleEffect(product.featured ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .disabled(storeKit.purchaseInProgress)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            if storeKit.restoreInProgress {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(AppColors.textTertiary)
                    Text("Restoring...")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                }
            } else {
                Text("Restore Purchases")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textTertiary)
                    .underline()
            }
        }
        .buttonStyle(.plain)
        .disabled(storeKit.purchaseInProgress || storeKit.restoreInProgress)
        .padding(.bottom, 16)
    }
    
    // MARK: - Disclaimer
    
    private var disclaimer: some View {
        Text("Lock Mode credits are consumable. Restore only recovers unprocessed purchases. Used credits cannot be refunded or restored.")
            .font(.system(size: 11))
            .foregroundColor(AppColors.textMuted)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

// Custom badge shape
struct BadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 6
        
        // Top left rounded
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        // Top right - goes into parent
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Bottom right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        // Bottom left
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        path.closeSubpath()
        return path
    }
}

#Preview {
    PurchaseView()
        .environmentObject(PactStore())
        .environmentObject(StoreKitManager())
}
