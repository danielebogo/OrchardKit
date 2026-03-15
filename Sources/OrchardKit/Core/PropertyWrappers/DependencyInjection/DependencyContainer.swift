public protocol DependencyContainer {
    static var current: Self { get set }

    static subscript<K>(key: K.Type) -> K.Value where K: DependencyKey { get set }

    static subscript<T>(_ keyPath: WritableKeyPath<Self, T>) -> T { get set }
}

public extension DependencyContainer {
    static subscript<K>(key: K.Type) -> K.Value where K: DependencyKey {
        get {
            key.currentValue
        }
        set {
            key.currentValue = newValue
        }
    }

    static subscript<T>(_ keyPath: WritableKeyPath<Self, T>) -> T {
        get {
            current[keyPath: keyPath]
        }
        set {
            current[keyPath: keyPath] = newValue
        }
    }
}
