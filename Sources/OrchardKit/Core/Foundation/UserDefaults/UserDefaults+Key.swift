import Foundation

/// Adds typed keys for values stored in `UserDefaults`.
public extension UserDefaults {
    /// A typed wrapper around a `UserDefaults` key name.
    ///
    /// Use a key whose `Value` matches the type expected at the call site. Stored values must still be compatible with
    /// `UserDefaults` property-list storage.
    struct Key<Value> {
        /// The raw key name used by `UserDefaults`.
        public let name: String

        /// Creates a typed key with the raw `UserDefaults` key name.
        ///
        /// - Parameter name: The string key used for storage.
        public init(name: String) {
            self.name = name
        }
    }
}
