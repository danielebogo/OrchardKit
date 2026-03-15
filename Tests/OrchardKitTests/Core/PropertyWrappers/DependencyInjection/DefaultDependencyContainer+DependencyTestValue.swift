@testable import OrchardKit

extension DefaultDependencyContainer {
    var dependencyValue: String {
        get {
            Self[DependencyTestKey.self]
        }
        set {
            Self[DependencyTestKey.self] = newValue
        }
    }
}
