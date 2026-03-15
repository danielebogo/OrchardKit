import Foundation

@propertyWrapper
public struct UserDefault<Value> {
    private let key: UserDefaults.Key<Value>
    private let defaultValue: Value?
    private let userDefaults: UserDefaults

    public var wrappedValue: Value? {
        get {
            userDefaults[key, default: defaultValue]
        }
        set {
            userDefaults[key] = newValue
        }
    }

    public var projectedValue: UserDefault<Value> {
        self
    }

    public init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    public func delete() {
        userDefaults[key] = nil
    }
}
