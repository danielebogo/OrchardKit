import Foundation

public extension UserDefaults {
    /// Accesses a typed `UserDefaults` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to the expected type.
    /// - Returns: The stored value, the fallback value, or `nil`.
    @available(
        *,
        unavailable,
        message: "UserDefaults subscript supports only String, Bool, Int, Float, Double, Data, and Date values."
    )
    subscript<T>(
        key: Key<T>,
        default defaultProvider: @autoclosure () -> T? = nil
    ) -> T? {
        get {
            fatalError("Unsupported UserDefaults value type.")
        }
        set {
            fatalError("Unsupported UserDefaults value type.")
        }
    }

    /// Accesses a typed `String` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to `String`.
    /// - Returns: The stored value, the fallback value, or `nil`.
    subscript(
        key: Key<String>,
        default defaultProvider: @autoclosure () -> String? = nil
    ) -> String? {
        get {
            storedValue(for: key, default: defaultProvider)
        }
        set {
            setStoredValue(newValue, for: key)
        }
    }

    /// Accesses a typed `Bool` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to `Bool`.
    /// - Returns: The stored value, the fallback value, or `nil`.
    subscript(
        key: Key<Bool>,
        default defaultProvider: @autoclosure () -> Bool? = nil
    ) -> Bool? {
        get {
            storedValue(for: key, default: defaultProvider)
        }
        set {
            setStoredValue(newValue, for: key)
        }
    }

    /// Accesses a typed `Int` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to `Int`.
    /// - Returns: The stored value, the fallback value, or `nil`.
    subscript(
        key: Key<Int>,
        default defaultProvider: @autoclosure () -> Int? = nil
    ) -> Int? {
        get {
            storedValue(for: key, default: defaultProvider)
        }
        set {
            setStoredValue(newValue, for: key)
        }
    }

    /// Accesses a typed `Float` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to `Float`.
    /// - Returns: The stored value, the fallback value, or `nil`.
    subscript(
        key: Key<Float>,
        default defaultProvider: @autoclosure () -> Float? = nil
    ) -> Float? {
        get {
            storedValue(for: key, default: defaultProvider)
        }
        set {
            setStoredValue(newValue, for: key)
        }
    }

    /// Accesses a typed `Double` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to `Double`.
    /// - Returns: The stored value, the fallback value, or `nil`.
    subscript(
        key: Key<Double>,
        default defaultProvider: @autoclosure () -> Double? = nil
    ) -> Double? {
        get {
            storedValue(for: key, default: defaultProvider)
        }
        set {
            setStoredValue(newValue, for: key)
        }
    }

    /// Accesses a typed `Data` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to `Data`.
    /// - Returns: The stored value, the fallback value, or `nil`.
    subscript(
        key: Key<Data>,
        default defaultProvider: @autoclosure () -> Data? = nil
    ) -> Data? {
        get {
            storedValue(for: key, default: defaultProvider)
        }
        set {
            setStoredValue(newValue, for: key)
        }
    }

    /// Accesses a typed `Date` value.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - defaultProvider: A fallback value returned when no stored value
    ///     exists or the stored value cannot be cast to `Date`.
    /// - Returns: The stored value, the fallback value, or `nil`.
    subscript(
        key: Key<Date>,
        default defaultProvider: @autoclosure () -> Date? = nil
    ) -> Date? {
        get {
            storedValue(for: key, default: defaultProvider)
        }
        set {
            setStoredValue(newValue, for: key)
        }
    }

    private func storedValue<T>(
        for key: Key<T>,
        default defaultProvider: () -> T?
    ) -> T? {
        object(forKey: key.name) as? T ?? defaultProvider()
    }

    private func setStoredValue<T>(
        _ value: T?,
        for key: Key<T>
    ) {
        set(value, forKey: key.name)
    }
}
