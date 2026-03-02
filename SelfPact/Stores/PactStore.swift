import Foundation
import SwiftUI
import Combine

// MARK: - Pact Store
@MainActor
class PactStore: ObservableObject {
    @Published var pacts: [Pact] = []
    @Published var userData: UserData = .default
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
    
    func sealPact(id: String) -> Bool {
        guard userData.creditCount > 0 else { return false }
        
        if let index = pacts.firstIndex(where: { $0.id == id }) {
            pacts[index].isSealed = true
            pacts[index].sealTimestamp = Date()
            pacts[index].status = .sealed
            savePacts()
            
            userData.creditCount -= 1
            saveUserData()
            return true
        }
        return false
    }
    
    func updatePact(id: String, title: String? = nil, why: String? = nil, measurableTarget: String? = nil, targetDate: Date? = nil) {
        if let index = pacts.firstIndex(where: { $0.id == id }) {
            if let title = title { pacts[index].title = title }
            if let why = why { pacts[index].why = why }
            if let measurableTarget = measurableTarget { pacts[index].measurableTarget = measurableTarget }
            if let targetDate = targetDate { pacts[index].targetDate = targetDate }
            savePacts()
        }
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
    
    func addCredits(_ count: Int) {
        userData.creditCount += count
        saveUserData()
    }
    
    func setOnboardingSeen() {
        userData.hasSeenOnboarding = true
        saveUserData()
    }
    
    func toggleICloudSync(_ enabled: Bool) {
        userData.iCloudSyncEnabled = enabled
        saveUserData()
    }
}
