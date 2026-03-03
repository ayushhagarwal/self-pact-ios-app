import Foundation
import StoreKit
import Combine

// MARK: - IAP Product IDs
enum IAPProduct: String, CaseIterable {
    case oneSeal = "com.selfpact.1seal"
    case fiveSeals = "com.selfpact.5seals"
    
    var credits: Int {
        switch self {
        case .oneSeal: return 1
        case .fiveSeals: return 5
        }
    }
}

// MARK: - Product Model for UI
struct IAPProductModel: Identifiable {
    let id: String
    let product: Product
    let displayTitle: String
    let displayDescription: String
    let badge: String?
    let featured: Bool
    
    var credits: Int {
        IAPProduct(rawValue: id)?.credits ?? 0
    }
    
    var formattedPrice: String {
        product.displayPrice
    }
}

// MARK: - StoreKit Manager
@MainActor
class StoreKitManager: ObservableObject {
    @Published var products: [IAPProductModel] = []
    @Published var purchaseInProgress = false
    @Published var purchaseError: String?
    @Published var restoreInProgress = false
    @Published var restoreSuccess: Bool = false
    @Published var restoredCredits: Int = 0
    
    private var pactStore: PactStore?
    private var transactionListener: Task<Void, Error>?
    private var processedTransactionIDs: Set<UInt64> = []
    
    private let processedKey = "selfpact_processed_transactions"
    
    init() {
        loadProcessedTransactions()
        startTransactionListener()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Setup
    
    func configure(with pactStore: PactStore) {
        self.pactStore = pactStore
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        do {
            let productIDs = IAPProduct.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)
            
            // Map to display models with UI metadata
            self.products = storeProducts.compactMap { product -> IAPProductModel? in
                let productID = product.id
                
                switch productID {
                case IAPProduct.oneSeal.rawValue:
                    return IAPProductModel(
                        id: productID,
                        product: product,
                        displayTitle: "1 Seal Credit",
                        displayDescription: "Seal one commitment contract.",
                        badge: nil,
                        featured: false
                    )
                    
                case IAPProduct.fiveSeals.rawValue:
                    return IAPProductModel(
                        id: productID,
                        product: product,
                        displayTitle: "5 Seal Credits",
                        displayDescription: "Best value — seal five pacts.",
                        badge: "Save 50%",
                        featured: true
                    )
                    
                default:
                    return nil
                }
            }
            
            // Sort to ensure 5-pack appears first (featured)
            self.products.sort { $0.featured && !$1.featured }
            
        } catch {
            purchaseError = "Failed to load products. Please try again."
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ productModel: IAPProductModel) async -> Bool {
        guard !purchaseInProgress else { return false }
        
        purchaseInProgress = true
        purchaseError = nil
        
        defer {
            purchaseInProgress = false
        }
        
        do {
            let result = try await productModel.product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify and process the transaction
                let processed = await handleVerification(verification, productID: productModel.id)
                return processed
                
            case .userCancelled:
                purchaseError = nil // User cancelled is not an error
                return false
                
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
                
            @unknown default:
                purchaseError = "Unknown purchase result."
                return false
            }
            
        } catch {
            purchaseError = "Purchase failed. Please try again."
            return false
        }
    }
    
    // MARK: - Transaction Processing (Centralized)
    
    /// Centralized transaction processing used by purchase, restore, listener, and launch check
    /// Returns number of credits granted (0 if transaction was not processed)
    private func processTransaction(_ verification: VerificationResult<Transaction>) async -> Int {
        switch verification {
        case .verified(let transaction):
            // Filter: Only process our product IDs
            guard transaction.productID == IAPProduct.oneSeal.rawValue ||
                  transaction.productID == IAPProduct.fiveSeals.rawValue else {
                await transaction.finish()
                return 0
            }
            
            // Check if already processed (prevent duplicates)
            guard !processedTransactionIDs.contains(transaction.id) else {
                await transaction.finish()
                return 0
            }
            
            // Validate product ID
            guard let iapProduct = IAPProduct(rawValue: transaction.productID) else {
                await transaction.finish()
                return 0
            }
            
            // Ensure pactStore is configured
            guard let pactStore = pactStore else {
                // DO NOT mark as processed - allow retry on next launch
                await transaction.finish()
                return 0
            }
            
            let credits = iapProduct.credits
            
            // CRITICAL: Mark as processed FIRST to prevent race condition
            // If app crashes after this but before credit grant, we prefer
            // losing credits over granting duplicates (Apple's recommendation)
            processedTransactionIDs.insert(transaction.id)
            saveProcessedTransactions()
            
            // Grant credits atomically
            pactStore.addCredits(credits)
            
            // Finish transaction
            await transaction.finish()
            
            return credits
            
        case .unverified(let transaction, _):
            // Still finish unverified transactions to prevent pending state
            await transaction.finish()
            return 0
        }
    }
    
    // MARK: - Transaction Verification (for Purchase Flow)
    
    private func handleVerification(_ verification: VerificationResult<Transaction>, productID: String) async -> Bool {
        let credits = await processTransaction(verification)
        
        if credits == 0 {
            // Check if it was unverified
            if case .unverified = verification {
                purchaseError = "Transaction could not be verified."
            }
            return false
        }
        
        return true
    }
    
    // MARK: - Transaction Listener
    
    private func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }
    
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        // Use centralized processing
        _ = await processTransaction(result)
    }
    
    // MARK: - Pending Transactions Check (on Launch)
    
    func checkPendingTransactions() async {
        // Check all transactions on app launch for unprocessed purchases
        for await result in Transaction.all {
            _ = await processTransaction(result)
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        restoreInProgress = true
        purchaseError = nil
        restoreSuccess = false
        restoredCredits = 0
        
        defer {
            restoreInProgress = false
        }
        
        // For consumables: Check Transaction.all for unprocessed transactions
        // Filter only verified and our product IDs (done in processTransaction)
        var totalRestored = 0
        
        for await result in Transaction.all {
            let credits = await processTransaction(result)
            totalRestored += credits
        }
        
        if totalRestored > 0 {
            restoreSuccess = true
            restoredCredits = totalRestored
        } else {
            purchaseError = "No restorable purchases found for this Apple ID."
        }
    }
    
    // MARK: - Processed Transactions Persistence
    // NOTE: Stored locally only. No cloud sync to ensure transaction privacy.
    
    private func loadProcessedTransactions() {
        if let data = UserDefaults.standard.data(forKey: processedKey),
           let ids = try? JSONDecoder().decode([UInt64].self, from: data) {
            processedTransactionIDs = Set(ids)
        }
    }
    
    private func saveProcessedTransactions() {
        let ids = Array(processedTransactionIDs)
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: processedKey)
        }
    }
}
