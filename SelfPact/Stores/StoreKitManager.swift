import Foundation
import StoreKit
import Combine

enum SelfPactProduct {
    static let lifetime = "com.selfpact.plus.lifetime"

    // Kept only so previous credit purchasers can be upgraded fairly.
    static let legacyCreditIDs: Set<String> = [
        "com.selfpact.1seal",
        "com.selfpact.5seals"
    ]
}

@MainActor
final class StoreKitManager: ObservableObject {
    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var hasLifetimeAccess = false
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var restoreInProgress = false
    @Published var purchaseError: String?

    private weak var pactStore: PactStore?
    private var transactionListener: Task<Void, Never>?
    private var hasVerifiedLifetimeEntitlement = false
    private var hasLegacyLifetimeAccess: Bool

    private let legacyMigrationKey = "selfpact_legacy_purchase_lifetime_access"

    init() {
        hasLegacyLifetimeAccess = UserDefaults.standard.bool(forKey: legacyMigrationKey)
        hasLifetimeAccess = hasLegacyLifetimeAccess
        startTransactionListener()
    }

    deinit {
        transactionListener?.cancel()
    }

    func configure(with pactStore: PactStore) {
        self.pactStore = pactStore

        // Preserve value for customers who still have locally stored credits.
        if pactStore.userData.legacyCreditCount > 0 {
            grantLegacyLifetimeAccess()
        } else {
            syncAccessToPactStore()
        }
    }

    func prepareStore() async {
        async let productLoad: Void = loadProduct()
        async let entitlementRefresh: Void = refreshEntitlements()
        _ = await (productLoad, entitlementRefresh)
    }

    func loadProduct() async {
        guard lifetimeProduct == nil, !isLoadingProduct else { return }

        isLoadingProduct = true
        purchaseError = nil
        defer { isLoadingProduct = false }

        do {
            lifetimeProduct = try await Product.products(for: [SelfPactProduct.lifetime]).first
            if lifetimeProduct == nil {
                purchaseError = "GoalLock Plus is temporarily unavailable. Please try again later."
            }
        } catch is CancellationError {
            return
        } catch {
            purchaseError = "GoalLock Plus could not be loaded. Please try again."
        }
    }

    func purchaseLifetime() async -> Bool {
        guard !purchaseInProgress else { return false }

        if lifetimeProduct == nil {
            await loadProduct()
        }

        guard let lifetimeProduct else {
            purchaseError = "GoalLock Plus is temporarily unavailable. Please try again later."
            return false
        }

        purchaseInProgress = true
        purchaseError = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await lifetimeProduct.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification,
                      transaction.productID == SelfPactProduct.lifetime else {
                    purchaseError = "The purchase could not be verified."
                    return false
                }

                hasVerifiedLifetimeEntitlement = transaction.revocationDate == nil
                updateLifetimeAccess()
                await transaction.finish()
                return hasLifetimeAccess

            case .userCancelled:
                return false

            case .pending:
                purchaseError = "The purchase is awaiting approval. Access will unlock automatically once approved."
                return false

            @unknown default:
                purchaseError = "The purchase could not be completed. Please try again."
                return false
            }
        } catch is CancellationError {
            return false
        } catch {
            purchaseError = "The purchase failed. Please try again."
            return false
        }
    }

    func restorePurchases() async -> Bool {
        guard !restoreInProgress else { return false }

        restoreInProgress = true
        purchaseError = nil
        defer { restoreInProgress = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()

            if hasLifetimeAccess {
                return true
            }

            purchaseError = "No GoalLock Plus purchase was found for this Apple ID."
            return false
        } catch is CancellationError {
            return false
        } catch {
            purchaseError = "Purchases could not be restored. Please try again."
            return false
        }
    }

    func refreshEntitlements() async {
        var foundLifetimeEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == SelfPactProduct.lifetime else { continue }
            foundLifetimeEntitlement = transaction.revocationDate == nil
        }

        hasVerifiedLifetimeEntitlement = foundLifetimeEntitlement

        if !hasLegacyLifetimeAccess {
            await migrateLegacyPurchaseHistory()
        }

        updateLifetimeAccess()
    }

    private func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }

        if transaction.productID == SelfPactProduct.lifetime {
            await refreshEntitlements()
            await transaction.finish()
        } else if SelfPactProduct.legacyCreditIDs.contains(transaction.productID) {
            grantLegacyLifetimeAccess()
            await transaction.finish()
        }
    }

    private func migrateLegacyPurchaseHistory() async {
        for await result in Transaction.all {
            guard case .verified(let transaction) = result else { continue }
            if SelfPactProduct.legacyCreditIDs.contains(transaction.productID) {
                grantLegacyLifetimeAccess()
                return
            }
        }
    }

    private func grantLegacyLifetimeAccess() {
        hasLegacyLifetimeAccess = true
        UserDefaults.standard.set(true, forKey: legacyMigrationKey)
        updateLifetimeAccess()
    }

    private func updateLifetimeAccess() {
        hasLifetimeAccess = hasVerifiedLifetimeEntitlement || hasLegacyLifetimeAccess
        syncAccessToPactStore()
    }

    private func syncAccessToPactStore() {
        pactStore?.setLifetimeAccess(hasLifetimeAccess)
    }
}
