import Foundation
import SwiftUI
import Combine

// MARK: - Pact Store
@MainActor
class PactStore: ObservableObject {
    static let freePactLimit = 3

    @Published private(set) var pacts: [Pact] = []
    @Published private(set) var userData: UserData = .default
    @Published private(set) var hasUsedFreeLock = false
    @Published private(set) var hasLifetimeAccess = false
    @Published var isLoading: Bool = true
    
    private let pactsKey = "selfpact_pacts"
    private let userKey = "selfpact_user"
    private let freeLockUsedKey = "selfpact_has_used_free_lock"
    
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

    var todayPacts: [Pact] {
        let now = Date()

        return pacts
            .filter { pact in
                guard pact.status == .draft || pact.status == .sealed else { return false }
                return pact.isReady || isScheduledForCheckIn(pact, on: now)
            }
            .sorted { lhs, rhs in
                if lhs.isReady != rhs.isReady {
                    return lhs.isReady
                }
                if lhs.status != rhs.status {
                    return lhs.status == .sealed
                }
                return lhs.targetDate < rhs.targetDate
            }
    }
    
    var completedPacts: [Pact] {
        pacts.filter { $0.status == .completed }
    }

    var archivedPacts: [Pact] {
        pacts.filter { $0.status == .completed || $0.status == .broken }
    }

    var lockedPactCount: Int {
        pacts.filter { pact in
            pact.isSealed || pact.sealTimestamp != nil || pact.status == .completed || pact.status == .broken
        }.count
    }

    var freePactsRemaining: Int {
        max(Self.freePactLimit - lockedPactCount, 0)
    }

    var canSealAnotherPact: Bool {
        hasLifetimeAccess || freePactsRemaining > 0
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

        if UserDefaults.standard.object(forKey: freeLockUsedKey) != nil {
            hasUsedFreeLock = UserDefaults.standard.bool(forKey: freeLockUsedKey)
        } else {
            hasUsedFreeLock = pacts.contains { pact in
                pact.isSealed || pact.status == .completed || pact.status == .broken
            }
            UserDefaults.standard.set(hasUsedFreeLock, forKey: freeLockUsedKey)
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
    
    // MARK: - Seal Pact
    func sealPact(id: String) -> Bool {
        // Find pact index
        guard let index = pacts.firstIndex(where: { $0.id == id }) else { return false }
        
        // Guard: Can only seal draft pacts
        guard pacts[index].status == .draft else { return false }

        // Three lifetime pact locks are included. GoalLock Plus removes the limit.
        guard canSealAnotherPact else { return false }
        
        // Now seal the pact
        pacts[index].isSealed = true
        pacts[index].sealTimestamp = Date()
        pacts[index].status = .sealed
        hasUsedFreeLock = true
        UserDefaults.standard.set(true, forKey: freeLockUsedKey)
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
        guard let pact = pacts.first(where: { $0.id == id }), pact.status == .draft else {
            return
        }

        pacts.removeAll { $0.id == id }
        savePacts()

        Task {
            await ReminderManager.cancelReminders(for: pact.id)
        }
    }

    func breakPact(id: String, reason: String) -> Bool {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty,
              let index = pacts.firstIndex(where: { $0.id == id }),
              pacts[index].status == .sealed else {
            return false
        }

        pacts[index].status = .broken
        pacts[index].brokenAt = Date()
        pacts[index].breakReason = trimmedReason
        savePacts()

        Task {
            await ReminderManager.cancelReminders(for: id)
        }

        return true
    }
    
    func addCheckIn(pactId: String, progress: Int, note: String?) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }),
           pacts[index].status == .draft || pacts[index].status == .sealed {
            let checkIn = CheckIn(progress: progress, note: note)
            pacts[index].checkIns.append(checkIn)
            savePacts()
        }
    }

    func addTodayCheckIn(pactId: String, progress: Int, note: String?, nextAction: String?) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }),
           pacts[index].status == .draft || pacts[index].status == .sealed {
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
        if let index = pacts.firstIndex(where: { $0.id == pactId }),
           pacts[index].status == .draft || pacts[index].status == .sealed {
            pacts[index].nextAction = sanitizedOptional(nextAction)
            savePacts()
        }
    }

    func updateCadence(pactId: String, cadence: GoalCadence, reminderWeekdays: [Int]? = nil) {
        if let index = pacts.firstIndex(where: { $0.id == pactId }),
           pacts[index].status == .draft || pacts[index].status == .sealed {
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
        let checkInsByDay = Dictionary(grouping: pact.checkIns) {
            calendar.startOfDay(for: $0.date)
        }

        let today = calendar.startOfDay(for: Date())
        var cursor = mostRecentScheduledDay(for: pact, onOrBefore: today)
        var streak = 0

        if cursor == today {
            let todayCheckIns = checkInsByDay[today] ?? []
            if todayCheckIns.isEmpty {
                cursor = previousScheduledDay(for: pact, before: today)
            } else if !todayCheckIns.contains(where: { $0.progress > 0 }) {
                return 0
            }
        }

        while let scheduledDay = cursor {
            guard (checkInsByDay[scheduledDay] ?? []).contains(where: { $0.progress > 0 }) else {
                break
            }

            streak += 1
            cursor = previousScheduledDay(for: pact, before: scheduledDay)
        }

        return streak
    }

    func isScheduledForCheckIn(_ pact: Pact, on date: Date) -> Bool {
        scheduledWeekdays(for: pact).contains(Calendar.current.component(.weekday, from: date))
    }
    
    func completePact(id: String, outcome: PactOutcome, reflection: String? = nil) {
        if let index = pacts.firstIndex(where: { $0.id == id }), pacts[index].status == .sealed {
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
    
    func setLifetimeAccess(_ hasAccess: Bool) {
        hasLifetimeAccess = hasAccess
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

    private func scheduledWeekdays(for pact: Pact) -> Set<Int> {
        if let weekdays = pact.reminderWeekdays, !weekdays.isEmpty {
            return Set(weekdays)
        }

        switch pact.cadence {
        case .weekdays:
            return [2, 3, 4, 5, 6]
        case .custom:
            return [2, 3, 4, 5, 6]
        case .daily, nil:
            return [1, 2, 3, 4, 5, 6, 7]
        }
    }

    private func mostRecentScheduledDay(for pact: Pact, onOrBefore date: Date) -> Date? {
        let calendar = Calendar.current
        var candidate = calendar.startOfDay(for: date)

        for _ in 0..<7 {
            if isScheduledForCheckIn(pact, on: candidate) {
                return candidate
            }
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: candidate) else {
                return nil
            }
            candidate = previousDay
        }

        return nil
    }

    private func previousScheduledDay(for pact: Pact, before date: Date) -> Date? {
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return mostRecentScheduledDay(for: pact, onOrBefore: previousDay)
    }
}
