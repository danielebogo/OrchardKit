import Foundation
@testable import OrchardKit

struct DependencyTestKey: DependencyKey {
    private final class Storage: @unchecked Sendable {
        let lock = NSLock()
        var currentValue = "live"
    }

    private static let storage = Storage()

    static var currentValue: String {
        get {
            storage.lock.lock()
            defer {
                storage.lock.unlock()
            }
            return storage.currentValue
        }
        set {
            storage.lock.lock()
            defer {
                storage.lock.unlock()
            }
            storage.currentValue = newValue
        }
    }
}
