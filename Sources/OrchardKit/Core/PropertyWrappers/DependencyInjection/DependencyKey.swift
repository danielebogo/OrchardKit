public protocol DependencyKey {
    associatedtype Value

    static var currentValue: Value { get set }
}
