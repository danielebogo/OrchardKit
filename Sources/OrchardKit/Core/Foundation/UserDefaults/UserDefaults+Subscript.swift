import Foundation

public extension UserDefaults {
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
