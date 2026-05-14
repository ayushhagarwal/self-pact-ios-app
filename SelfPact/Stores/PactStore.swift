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

    var activeTodayPact: Pact? {
        pacts
            .filter { $0.status != .completed }
            .sorted { lhs, rhs in
                if lhs.status != rhs.status {
                    return lhs.status == .sealed
                }
                return lhs.targetDate < rhs.targetDate
            }
            .first
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
    
    var hasUsedFreeLock: Bool {
        pacts.contains { $0.status == .sealed || $0.status == .completed }
    }

    // MARK: - Pact Operations

    func createPact(
        title: String,
        why: String?,
        measurableTarget: String?,
        nextAction: String? = nil,
        cadence: GoalCadence? = nil,
        reminderWeekdays: [Int]? = nil,
        targetDate: Date
    ) -> Pact {
        let newPact = Pact(
            title: title,
            why: why,
            measurableTarget: measurableTarget,
            nextAction: sanitizedOptional(nextAction),
            cadence: cadence,
            reminderWeekdays: normalizedReminderWeekdays(for: cadence, weekdays: reminderWeekdays),
            targetDate: targetDate
        )
        pacts.insert(newPact, at: 0)
        savePacts()
        return newPact
    }
    
    // MARK: - Seal Pact (Atomic & Crash-Safe)
    // SECURITY: Credit deducted BEFORE pact sealing to prevent race condition exploit
    func sealPact(id: String) -> Bool {
        // Find pact index
        guard let index = pacts.firstIndex(where: { $0.id == id }) else { return false }
        
        // Guard: Can only seal draft pacts
        guard pacts[index].status == .draft else { return false }

        let shouldConsumeCredit = hasUsedFreeLock

        // Guard: First lock is free; later locks require Lock Mode credits.
        guard !shouldConsumeCredit || userData.creditCount > 0 else { return false }
        
        if shouldConsumeCredit {
            // CRITICAL: Deduct credit FIRST to prevent force-quit exploit
            userData.creditCount -= 1
            // Enforce non-negative credits
            userData.creditCount = max(userData.creditCount, 0)
            saveUserData()
        }
        
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
        let removedPacts = pacts.filter { $0.id == id }
        pacts.removeAll { $0.id == id }
        savePacts()

        for pact in removedPacts {
            Task {
                await ReminderManager.cancelReminders(for: pact.id)
            }
        }
    }
    
    func addCheckIn(pactId: String, progress: Int, note: String?) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }) {
            let checkIn = CheckIn(progress: progress, note: note)
            pacts[index].checkIns.append(checkIn)
            savePacts()
        }
    }

    func addTodayCheckIn(pactId: String, progress: Int, note: String?, nextAction: String?) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }) {
            let checkIn = CheckIn(progress: progress, note: note)
            if let existingIndex = pacts[index].checkIns.lastIndex(where: {
                Calendar.current.isDate($0.date, inSameDayAs: Date())
            }) {
                pacts[index].checkIns[existingIndex] = checkIn
            } else {
                pacts[index].checkIns.append(checkIn)
            }
            pacts[index].nextAction = sanitizedOptional(nextAction)
            savePacts()
        }
    }

    func updateNextAction(pactId: String, nextAction: String?) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }) {
            pacts[index].nextAction = sanitizedOptional(nextAction)
            savePacts()
        }
    }

    func updateCadence(pactId: String, cadence: GoalCadence, reminderWeekdays: [Int]? = nil) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }) {
            pacts[index].cadence = cadence
            pacts[index].reminderWeekdays = normalizedReminderWeekdays(for: cadence, weekdays: reminderWeekdays)
            savePacts()
        }
    }

    func lastCheckIn(for pact: Pact) -> CheckIn? {
        pact.checkIns.max { $0.date < $1.date }
    }

    func currentStreak(for pact: Pact) -> Int {
        let calendar = Calendar.current
        let activeDays = Set(
            pact.checkIns
                .filter { $0.progress > 0 }
                .map { calendar.startOfDay(for: $0.date) }
        )

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var cursor = activeDays.contains(today) ? today : yesterday
        var streak = 0

        while activeDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }
    
    func completePact(id: String, outcome: PactOutcome, reflection: String? = nil) {
        if let index = pacts.firstIndex(where: { $0.id == id }) {
            pacts[index].status = .completed
            pacts[index].outcome = outcome
            pacts[index].reflection = reflection
            let completedPactId = pacts[index].id
            savePacts()

            Task {
                await ReminderManager.cancelReminders(for: completedPactId)
            }
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

    private func sanitizedOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalizedReminderWeekdays(for cadence: GoalCadence?, weekdays: [Int]?) -> [Int]? {
        switch cadence {
        case .daily:
            return [1, 2, 3, 4, 5, 6, 7]
        case .weekdays:
            return [2, 3, 4, 5, 6]
        case .custom:
            let selected = Array(Set(weekdays ?? [])).filter { (1...7).contains($0) }.sorted()
            return selected.isEmpty ? [2, 3, 4, 5, 6] : selected
        case nil:
            return nil
        }
    }
}
