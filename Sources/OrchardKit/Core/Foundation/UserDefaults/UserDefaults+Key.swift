import Foundation

public extension UserDefaults {
    struct Key<Value> {
        public let name: String

        public init(name: String) {
            self.name = name
        }
    }
}
