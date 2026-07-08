import Foundation

enum ReviewPromptPolicy {
    private static let lastAttemptDateKey = "review_prompt_last_attempt_date"
    private static let lastAttemptVersionKey = "review_prompt_last_attempt_version"

    static let cooldown: TimeInterval = 180 * 24 * 60 * 60

    static func isEligible(
        after pact: Pact,
        completedPactCount: Int,
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> Bool {
        guard pact.outcome == .yes,
              completedPactCount > 0,
              pact.checkIns.count >= 3,
              now.timeIntervalSince(pact.createdAt) >= 6 * 24 * 60 * 60 else {
            return false
        }

        let currentVersion = appVersion(in: bundle)
        if defaults.string(forKey: lastAttemptVersionKey) == currentVersion {
            return false
        }

        if let lastAttempt = defaults.object(forKey: lastAttemptDateKey) as? Date,
           now.timeIntervalSince(lastAttempt) < cooldown {
            return false
        }

        return true
    }

    static func recordAttempt(
        at date: Date = Date(),
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) {
        defaults.set(date, forKey: lastAttemptDateKey)
        defaults.set(appVersion(in: bundle), forKey: lastAttemptVersionKey)
    }

    private static func appVersion(in bundle: Bundle) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }
}
