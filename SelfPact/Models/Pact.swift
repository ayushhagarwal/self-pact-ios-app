import Foundation

// MARK: - CheckIn Model
struct CheckIn: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    var progress: Int
    var note: String?
    
    init(id: String = UUID().uuidString, date: Date = Date(), progress: Int, note: String? = nil) {
        self.id = id
        self.date = date
        self.progress = progress
        self.note = note
    }
}

// MARK: - Pact Status
enum PactStatus: String, Codable {
    case draft
    case sealed
    case completed
    case broken
}

// MARK: - Pact Outcome
enum PactOutcome: String, Codable {
    case yes
    case partially
    case notYet = "not_yet"
}

enum GoalCadence: String, Codable, CaseIterable {
    case daily
    case weekdays
    case custom
}

// MARK: - Pact Model
struct Pact: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var why: String?
    var measurableTarget: String?
    var nextAction: String?
    var cadence: GoalCadence?
    var reminderWeekdays: [Int]?
    var imageUri: String?
    var targetDate: Date
    let createdAt: Date
    var isSealed: Bool
    var sealTimestamp: Date?
    var status: PactStatus
    var outcome: PactOutcome?
    var reflection: String?
    var brokenAt: Date?
    var breakReason: String?
    var checkIns: [CheckIn]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        why: String? = nil,
        measurableTarget: String? = nil,
        nextAction: String? = nil,
        cadence: GoalCadence? = nil,
        reminderWeekdays: [Int]? = nil,
        imageUri: String? = nil,
        targetDate: Date,
        createdAt: Date = Date(),
        isSealed: Bool = false,
        sealTimestamp: Date? = nil,
        status: PactStatus = .draft,
        outcome: PactOutcome? = nil,
        reflection: String? = nil,
        brokenAt: Date? = nil,
        breakReason: String? = nil,
        checkIns: [CheckIn] = []
    ) {
        self.id = id
        self.title = title
        self.why = why
        self.measurableTarget = measurableTarget
        self.nextAction = nextAction
        self.cadence = cadence
        self.reminderWeekdays = reminderWeekdays
        self.imageUri = imageUri
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.isSealed = isSealed
        self.sealTimestamp = sealTimestamp
        self.status = status
        self.outcome = outcome
        self.reflection = reflection
        self.brokenAt = brokenAt
        self.breakReason = breakReason
        self.checkIns = checkIns
    }
    
    var daysRemaining: Int {
        let now = Date()
        let diff = targetDate.timeIntervalSince(now)
        return max(0, Int(ceil(diff / (60 * 60 * 24))))
    }
    
    var timeProgress: Double {
        let start = createdAt.timeIntervalSince1970
        let end = targetDate.timeIntervalSince1970
        let now = Date().timeIntervalSince1970
        if now >= end { return 100 }
        if now <= start { return 0 }
        return ((now - start) / (end - start)) * 100
    }
    
    var isOverdue: Bool {
        daysRemaining <= 0 && status == .sealed
    }
    
    var isReady: Bool {
        status == .sealed && Date() >= targetDate
    }
    
    // SECURITY: Enforce immutability for sealed pacts
    var canModify: Bool {
        return status == .draft
    }
}

// MARK: - User Data
struct UserData: Codable, Equatable {
    // Retained only to migrate customers from the former consumable-credit model.
    var legacyCreditCount: Int
    var hasSeenOnboarding: Bool
    var iCloudSyncEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case legacyCreditCount = "creditCount"
        case hasSeenOnboarding
        case iCloudSyncEnabled
    }
    
    static let `default` = UserData(
        legacyCreditCount: 0,
        hasSeenOnboarding: false,
        iCloudSyncEnabled: false
    )
}
