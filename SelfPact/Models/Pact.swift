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
}

// MARK: - Pact Outcome
enum PactOutcome: String, Codable {
    case yes
    case partially
    case notYet = "not_yet"
}

// MARK: - Pact Model
struct Pact: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var why: String?
    var measurableTarget: String?
    var imageUri: String?
    var targetDate: Date
    let createdAt: Date
    var isSealed: Bool
    var sealTimestamp: Date?
    var status: PactStatus
    var outcome: PactOutcome?
    var reflection: String?
    var checkIns: [CheckIn]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        why: String? = nil,
        measurableTarget: String? = nil,
        imageUri: String? = nil,
        targetDate: Date,
        createdAt: Date = Date(),
        isSealed: Bool = false,
        sealTimestamp: Date? = nil,
        status: PactStatus = .draft,
        outcome: PactOutcome? = nil,
        reflection: String? = nil,
        checkIns: [CheckIn] = []
    ) {
        self.id = id
        self.title = title
        self.why = why
        self.measurableTarget = measurableTarget
        self.imageUri = imageUri
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.isSealed = isSealed
        self.sealTimestamp = sealTimestamp
        self.status = status
        self.outcome = outcome
        self.reflection = reflection
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
    var creditCount: Int
    var hasSeenOnboarding: Bool
    var iCloudSyncEnabled: Bool
    
    static let `default` = UserData(
        creditCount: 1,
        hasSeenOnboarding: false,
        iCloudSyncEnabled: false
    )
}
