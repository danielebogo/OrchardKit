import Foundation

/// Stores a directly supported scalar value in `UserDefaults`.
///
/// OrchardKit provides public initializers only for `String`, `Bool`, `Int`,
/// `Float`, `Double`, `Data`, and `Date`. Custom model types should be converted
/// to one of those storage representations before being stored.
@propertyWrapper
public struct UserDefault<Value> {
    /// Reads the current value from the backing store.
    private let getValue: () -> Value?

    /// Writes a new value to the backing store.
    private let setValue: (Value?) -> Void

    /// The current stored value.
    public var wrappedValue: Value? {
        get {
            getValue()
        }
        set {
            setValue(newValue)
        }
    }

    /// The wrapper instance used for storage operations such as deletion.
    public var projectedValue: UserDefault<Value> {
        self
    }

    /// Creates a user-default-backed property wrapper.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    @available(
        *,
        unavailable,
        message: "UserDefault supports only String, Bool, Int, Float, Double, Data, and Date values."
    )
    public init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        fatalError("Unsupported UserDefaults value type.")
    }

    private init(
        getValue: @escaping () -> Value?,
        setValue: @escaping (Value?) -> Void
    ) {
        self.getValue = getValue
        self.setValue = setValue
    }

    /// Removes the stored value from the backing `UserDefaults` store.
    public func delete() {
        setValue(nil)
    }
}

public extension UserDefault where Value == String {
    /// Creates a user-default-backed property wrapper for a `String` value.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.init(
            getValue: { userDefaults[key, default: defaultValue] },
            setValue: { userDefaults[key] = $0 }
        )
    }
}

public extension UserDefault where Value == Bool {
    /// Creates a user-default-backed property wrapper for a `Bool` value.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.init(
            getValue: { userDefaults[key, default: defaultValue] },
            setValue: { userDefaults[key] = $0 }
        )
    }
}

public extension UserDefault where Value == Int {
    /// Creates a user-default-backed property wrapper for an `Int` value.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.init(
            getValue: { userDefaults[key, default: defaultValue] },
            setValue: { userDefaults[key] = $0 }
        )
    }
}

public extension UserDefault where Value == Float {
    /// Creates a user-default-backed property wrapper for a `Float` value.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.init(
            getValue: { userDefaults[key, default: defaultValue] },
            setValue: { userDefaults[key] = $0 }
        )
    }
}

public extension UserDefault where Value == Double {
    /// Creates a user-default-backed property wrapper for a `Double` value.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.init(
            getValue: { userDefaults[key, default: defaultValue] },
            setValue: { userDefaults[key] = $0 }
        )
    }
}

public extension UserDefault where Value == Data {
    /// Creates a user-default-backed property wrapper for a `Data` value.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.init(
            getValue: { userDefaults[key, default: defaultValue] },
            setValue: { userDefaults[key] = $0 }
        )
    }
}

public extension UserDefault where Value == Date {
    /// Creates a user-default-backed property wrapper for a `Date` value.
    ///
    /// - Parameters:
    ///   - key: The typed key used to read and write the stored value.
    ///   - userDefaults: The backing store used by the wrapper.
    ///   - defaultValue: The fallback value returned when no stored value exists.
    init(
        key: UserDefaults.Key<Value>,
        userDefaults: UserDefaults = .standard,
        defaultValue: Value? = nil
    ) {
        self.init(
            getValue: { userDefaults[key, default: defaultValue] },
            setValue: { userDefaults[key] = $0 }
        )
    }
}
