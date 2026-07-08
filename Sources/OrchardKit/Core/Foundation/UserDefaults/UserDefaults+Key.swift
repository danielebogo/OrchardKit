import Foundation

public extension UserDefaults {
    /// A typed key for a value stored in `UserDefaults`.
    ///
    /// OrchardKit provides public initializers only for directly supported
    /// scalar storage types. Unsupported model types fail at compile time
    /// instead of reaching Foundation's runtime storage checks.
    struct Key<Value> {
        /// The raw key name used by the backing `UserDefaults` store.
        public let name: String

        /// Creates a typed user-defaults key for a supported storage type.
        ///
        /// - Parameter name: The raw key name used by the backing store.
        @available(
            *,
            unavailable,
            message: "UserDefaults.Key supports only String, Bool, Int, Float, Double, Data, and Date values."
        )
        public init(name: String) {
            fatalError("Unsupported UserDefaults value type.")
        }

        fileprivate init(supportedName name: String) {
            self.name = name
        }
    }
}

public extension UserDefaults.Key where Value == String {
    /// Creates a typed user-defaults key for a `String` value.
    ///
    /// - Parameter name: The raw key name used by the backing store.
    init(name: String) {
        self.init(supportedName: name)
    }
}

public extension UserDefaults.Key where Value == Bool {
    /// Creates a typed user-defaults key for a `Bool` value.
    ///
    /// - Parameter name: The raw key name used by the backing store.
    init(name: String) {
        self.init(supportedName: name)
    }
}

public extension UserDefaults.Key where Value == Int {
    /// Creates a typed user-defaults key for an `Int` value.
    ///
    /// - Parameter name: The raw key name used by the backing store.
    init(name: String) {
        self.init(supportedName: name)
    }
}

public extension UserDefaults.Key where Value == Float {
    /// Creates a typed user-defaults key for a `Float` value.
    ///
    /// - Parameter name: The raw key name used by the backing store.
    init(name: String) {
        self.init(supportedName: name)
    }
}

public extension UserDefaults.Key where Value == Double {
    /// Creates a typed user-defaults key for a `Double` value.
    ///
    /// - Parameter name: The raw key name used by the backing store.
    init(name: String) {
        self.init(supportedName: name)
    }
}

public extension UserDefaults.Key where Value == Data {
    /// Creates a typed user-defaults key for a `Data` value.
    ///
    /// - Parameter name: The raw key name used by the backing store.
    init(name: String) {
        self.init(supportedName: name)
    }
}

public extension UserDefaults.Key where Value == Date {
    /// Creates a typed user-defaults key for a `Date` value.
    ///
    /// - Parameter name: The raw key name used by the backing store.
    init(name: String) {
        self.init(supportedName: name)
    }
}
