@propertyWrapper
public struct Dependency<Container: DependencyContainer, Value> {
    private let keyPath: WritableKeyPath<Container, Value>
    private var container: Container

    public var wrappedValue: Value {
        get {
            container[keyPath: keyPath]
        }
        set {
            container[keyPath: keyPath] = newValue
        }
    }

    public init(
        container: Container,
        _ keyPath: WritableKeyPath<Container, Value>
    ) {
        self.container = container
        self.keyPath = keyPath
    }
}

public extension Dependency where Container == DefaultDependencyContainer {
    init(_ keyPath: WritableKeyPath<DefaultDependencyContainer, Value>) {
        self.init(
            container: DefaultDependencyContainer.current,
            keyPath
        )
    }
}
