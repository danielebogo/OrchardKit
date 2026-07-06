import Foundation

/// Adds typed key access to `UserDefaults`.
public extension UserDefaults {
    /// Accesses the value stored for a typed key, falling back to a default provider when no stored value of type `T` exists.
    ///
    /// The default provider is evaluated only when the key has no value that can be cast to `T`.
    ///
    /// - Parameters:
    ///   - key: The typed key that identifies the stored value.
    ///   - defaultProvider: A lazily evaluated fallback value.
    subscript<T>(
        key: Key<T>,
        default defaultProvider: @autoclosure () -> T? = nil
    ) -> T? {
        get {
            object(forKey: key.name) as? T ?? defaultProvider()
        }
        set {
            set(newValue, forKey: key.name)
        }
    }
}
