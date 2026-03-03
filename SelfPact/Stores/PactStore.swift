import Foundation
import SwiftUI
import Combine

// MARK: - Pact Store
@MainActor
class PactStore: ObservableObject {
    @Published private(set) var pacts: [Pact] = []
    @Published private(set) var userData: UserData = .default
    @Published var isLoading: Bool = true
    
    private let pactsKey = "selfpact_pacts"
    private let userKey = "selfpact_user"
    
    init() {
        loadData()
    }
    
    // MARK: - Computed Properties
    
    var draftPacts: [Pact] {
        pacts.filter { $0.status == .draft }
    }
    
    var sealedPacts: [Pact] {
        pacts.filter { $0.status == .sealed }
    }
    
    var completedPacts: [Pact] {
        pacts.filter { $0.status == .completed }
    }
    
    var revealablePacts: [Pact] {
        let now = Date()
        return pacts.filter { $0.status == .sealed && $0.targetDate <= now }
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        isLoading = true
        
        if let pactsData = UserDefaults.standard.data(forKey: pactsKey),
           let decoded = try? JSONDecoder().decode([Pact].self, from: pactsData) {
            pacts = decoded
        }
        
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let decoded = try? JSONDecoder().decode(UserData.self, from: userData) {
            self.userData = decoded
        }
        
        isLoading = false
    }
    
    private func savePacts() {
        if let encoded = try? JSONEncoder().encode(pacts) {
            UserDefaults.standard.set(encoded, forKey: pactsKey)
        }
    }
    
    private func saveUserData() {
        if let encoded = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }
    
    // MARK: - Pact Operations
    
    func createPact(title: String, why: String?, measurableTarget: String?, targetDate: Date) -> Pact {
        let newPact = Pact(
            title: title,
            why: why,
            measurableTarget: measurableTarget,
            targetDate: targetDate
        )
        pacts.insert(newPact, at: 0)
        savePacts()
        return newPact
    }
    
    // MARK: - Seal Pact (Atomic & Crash-Safe)
    // SECURITY: Credit deducted BEFORE pact sealing to prevent race condition exploit
    func sealPact(id: String) -> Bool {
        // Guard: Must have credits
        guard userData.creditCount > 0 else { return false }
        
        // Find pact index
        guard let index = pacts.firstIndex(where: { $0.id == id }) else { return false }
        
        // Guard: Can only seal draft pacts
        guard pacts[index].status == .draft else { return false }
        
        // CRITICAL: Deduct credit FIRST to prevent force-quit exploit
        userData.creditCount -= 1
        // Enforce non-negative credits
        userData.creditCount = max(userData.creditCount, 0)
        saveUserData()
        
        // Now seal the pact
        pacts[index].isSealed = true
        pacts[index].sealTimestamp = Date()
        pacts[index].status = .sealed
        savePacts()
        
        return true
    }
    
    // MARK: - Update Pact (Immutability Enforced)
    // SECURITY: Sealed pacts cannot be modified
    func updatePact(id: String, title: String? = nil, why: String? = nil, measurableTarget: String? = nil, targetDate: Date? = nil) {
        guard let index = pacts.firstIndex(where: { $0.id == id }) else { return }
        
        // CRITICAL: Only allow editing draft pacts
        guard pacts[index].canModify else {
            return
        }
        
        if let title = title { pacts[index].title = title }
        if let why = why { pacts[index].why = why }
        if let measurableTarget = measurableTarget { pacts[index].measurableTarget = measurableTarget }
        if let targetDate = targetDate { pacts[index].targetDate = targetDate }
        savePacts()
    }
    
    func deletePact(id: String) {
        pacts.removeAll { $0.id == id }
        savePacts()
    }
    
    func addCheckIn(pactId: String, progress: Int, note: String?) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }) {
            let checkIn = CheckIn(progress: progress, note: note)
            pacts[index].checkIns.append(checkIn)
            savePacts()
        }
    }
    
    func completePact(id: String, outcome: PactOutcome, reflection: String? = nil) {
        if let index = pacts.firstIndex(where: { $0.id == id }) {
            pacts[index].status = .completed
            pacts[index].outcome = outcome
            pacts[index].reflection = reflection
            savePacts()
        }
    }
    
    func getPact(id: String) -> Pact? {
        pacts.first { $0.id == id }
    }
    
    // MARK: - User Data Operations
    
    // SECURITY: Internal only - credits can only be granted via StoreKit
    internal func addCredits(_ count: Int) {
        userData.creditCount += count
        // Enforce non-negative credits
        userData.creditCount = max(userData.creditCount, 0)
        saveUserData()
    }
    
    func setOnboardingSeen() {
        userData.hasSeenOnboarding = true
        saveUserData()
    }
}
