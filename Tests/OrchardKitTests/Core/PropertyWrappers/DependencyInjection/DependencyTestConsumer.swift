@testable import OrchardKit

struct DependencyTestConsumer {
    @Dependency(\.dependencyValue) var dependencyValue: String
}
