import Foundation
@testable import OrchardKit

extension UserDefaults.Key where Value == String {
    static var userDefaultTestValue: UserDefaults.Key<String> {
        .init(name: "userDefaultTestValue")
    }
}
