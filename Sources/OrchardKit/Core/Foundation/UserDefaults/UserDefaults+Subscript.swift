import Foundation

public extension UserDefaults {
    subscript<T>(
        key: Key<T>,
        default defaultProvider: @autoclosure () -> T? = nil
    ) -> T? {
        get {
            if T.self == URL.self {
                return url(forKey: key.name) as? T ?? defaultProvider()
            }

            return object(forKey: key.name) as? T ?? defaultProvider()
        }
        set {
            if T.self == URL.self {
                set(newValue as? URL, forKey: key.name)
                return
            }

            set(newValue, forKey: key.name)
        }
    }
}
