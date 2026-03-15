import Foundation
@testable import OrchardKit

struct CustomDependencyContainer: DependencyContainer {
    private final class Storage: @unchecked Sendable {
        let lock = NSLock()
        var current = CustomDependencyContainer(service: "live")
    }

    private static let storage = Storage()

    static var current: CustomDependencyContainer {
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

    var service: String
}
