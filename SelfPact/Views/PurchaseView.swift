import SwiftUI

struct Product: Identifiable {
    let id: String
    let title: String
    let price: String
    let credits: Int
    let description: String
    var badge: String?
    var featured: Bool = false
}

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    
    @State private var showPurchaseAlert = false
    @State private var selectedProduct: Product?
    @State private var showRestoreAlert = false
    @State private var showSuccessAlert = false
    
    private let products: [Product] = [
        Product(
            id: "selfpact.seal.single",
            title: "1 Seal Credit",
            price: "$9.99",
            credits: 1,
            description: "Seal one commitment contract."
        ),
        Product(
            id: "selfpact.seal.pack5",
            title: "5 Seal Credits",
            price: "$24.99",
            credits: 5,
            description: "Best value — seal five pacts.",
            badge: "Save 50%",
            featured: true
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
            }
        }
        .alert("Purchase", isPresented: $showPurchaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Simulate Purchase") {
                if let product = selectedProduct {
                    pactStore.addCredits(product.credits)
                    showSuccessAlert = true
                }
            }
        } message: {
            if let product = selectedProduct {
                Text("This would initiate a StoreKit 2 purchase for \(product.title). For now, credits will be added for testing.")
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let product = selectedProduct {
                Text("\(product.credits) seal credit\(product.credits > 1 ? "s" : "") added.")
            }
        }
        .alert("Restore", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No previous purchases found. Consumable credits cannot be restored.")
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.surface)
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
                    .fill(AppColors.goldGlow)
                    .frame(width: 80, height: 80)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.goldGlowStrong)
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26))
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(.bottom, 24)
            
            Text("Lock Your\nCommitment")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-1.2)
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .padding(.bottom, 12)
            
            Text("Sealing makes your pact permanent.\nThis is your contract with your future self.")
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
                    .foregroundColor(AppColors.gold)
                
                Text("\(pactStore.userData.creditCount) credit\(pactStore.userData.creditCount != 1 ? "s" : "") available")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.gold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
        .padding(.bottom, 36)
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        VStack(spacing: 14) {
            // Featured product first (5-pack)
            ForEach(products.sorted(by: { $0.featured && !$1.featured })) { product in
                productCard(product: product)
                
                // Add "Most people choose 5" text after 5-pack
                if product.featured {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.gold.opacity(0.7))
                        
                        Text("Most people choose 5")
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
    
    private func productCard(product: Product) -> some View {
        Button {
            selectedProduct = product
            showPurchaseAlert = true
        } label: {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.4)
                    
                    Text(product.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(-0.1)
                }
                
                Spacer()
                
                Text(product.price)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(product.featured ? AppColors.gold : AppColors.textPrimary)
                    .tracking(-1.0)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(product.featured ? AppColors.goldGlow : AppColors.surface)
                    .shadow(color: product.featured ? AppColors.gold.opacity(0.15) : Color.clear, radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(product.featured ? AppColors.gold.opacity(0.4) : AppColors.border, lineWidth: product.featured ? 2 : 1)
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
                        .foregroundColor(AppColors.background)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.gold)
                        .clipShape(BadgeShape())
                    }
                },
                alignment: .topTrailing
            )
            .scaleEffect(product.featured ? 1.02 : 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button {
            showRestoreAlert = true
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textTertiary)
                .underline()
        }
        .buttonStyle(.plain)
        .padding(.bottom, 16)
    }
    
    // MARK: - Disclaimer
    
    private var disclaimer: some View {
        Text("Seal credits are consumable. Used credits cannot be refunded. Deleting a sealed pact does not restore your credit.")
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
}
