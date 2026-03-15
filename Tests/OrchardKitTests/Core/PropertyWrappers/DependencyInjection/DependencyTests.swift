import Testing
@testable import OrchardKit

@Suite("Dependency Injection", .serialized)
struct DependencyTests {
    @Test("Dependency reads from the default container")
    func dependencyReadsFromDefaultContainer() {
        let originalValue = DependencyTestKey.currentValue
        defer {
            DependencyTestKey.currentValue = originalValue
        }

        DependencyTestKey.currentValue = "expected"

        let consumer = DependencyTestConsumer()

        #expect(consumer.dependencyValue == "expected")
    }

    @Test("Dependency writes through the default container")
    func dependencyWritesThroughDefaultContainer() {
        let originalValue = DependencyTestKey.currentValue
        defer {
            DependencyTestKey.currentValue = originalValue
        }

        var consumer = DependencyTestConsumer()

        consumer.dependencyValue = "updated"

        #expect(DependencyTestKey.currentValue == "updated")
    }

    @Test("Dependency supports an injected custom container")
    func dependencySupportsCustomContainer() {
        let originalContainer = CustomDependencyContainer.current
        defer {
            CustomDependencyContainer.current = originalContainer
        }

        let injectedContainer = CustomDependencyContainer(service: "injected")
        var dependency = Dependency(
            container: injectedContainer,
            \.service
        )

        #expect(dependency.wrappedValue == "injected")

        dependency.wrappedValue = "updated"

        #expect(dependency.wrappedValue == "updated")
        #expect(CustomDependencyContainer.current.service == "live")
    }
}
