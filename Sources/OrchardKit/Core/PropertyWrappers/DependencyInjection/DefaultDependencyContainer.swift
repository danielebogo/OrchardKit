import Foundation

public struct DefaultDependencyContainer: DependencyContainer {
    private final class Storage: @unchecked Sendable {
        let lock = NSLock()
        var current = DefaultDependencyContainer()
    }

    private static let storage = Storage()

    public static var current: DefaultDependencyContainer {
        get {
            storage.lock.lock()
            defer {
                storage.lock.unlock()
            }
            return storage.current
        }
        set {
            storage.lock.lock()
            defer {
                storage.lock.unlock()
            }
            storage.current = newValue
        }
    }

    public init() {}
}
