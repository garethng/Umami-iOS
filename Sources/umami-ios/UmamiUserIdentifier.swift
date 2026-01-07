import Foundation

/// Persistent user identifier stored in UserDefaults.
///
/// This is used to distinguish users across app launches.
public enum UmamiUserIdentifier {
    public static let defaultUserDefaultsKey = "umami_ios.user_id"

    /// Returns a stable UUID string from UserDefaults, generating and persisting one if missing/invalid.
    public static func getOrCreate(
        defaults: UserDefaults = .standard,
        key: String = defaultUserDefaultsKey
    ) -> String {
        if let existing = defaults.string(forKey: key), UUID(uuidString: existing) != nil {
            return existing
        }

        let newID = UUID().uuidString
        defaults.set(newID, forKey: key)
        return newID
    }
}


