import Foundation

/// Stores an optional value in `UserDefaults` through a typed key.
///
/// The wrapped value is read and written directly against the configured `UserDefaults` instance. Values must be
/// compatible with `UserDefaults` property-list storage.
@propertyWrapper
public struct UserDefault<Value> {
    private let key: UserDefaults.Key<Value>
    private let defaultValue: Value?
    private let userDefaults: UserDefaults

    /// The value stored for the key, or the configured default value when no stored value exists.
    ///
    /// Setting this value writes through to `UserDefaults`; setting it to `nil` clears the stored value.
    public var wrappedValue: Value? {
        get {
            userDefaults[key, default: defaultValue]
        }
        set {
            userDefaults[key] = newValue
        }
    }

    /// The projected wrapper, allowing callers to access helper operations such as `delete()`.
    public var projectedValue: UserDefault<Value> {
        self
    }

    /// Creates a wrapper that reads and writes a typed key in `UserDefaults`.
    ///
    /// - Parameters:
    ///   - key: The typed key used for storage.
    ///   - userDefaults: The `UserDefaults` instance that owns the value.
    ///   - defaultValue: The value returned when the key has no stored value.
    public init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    /// Removes the stored value for the configured key.
    public func delete() {
        userDefaults[key] = nil
    }
}
