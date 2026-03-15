import Foundation
@testable import OrchardKit

struct UserDefaultTestSubject {
    @UserDefault(key: .userDefaultTestValue)
    var value: String?

    init(
        userDefaults: UserDefaults,
        defaultValue: String? = nil
    ) {
        self._value = UserDefault(
            key: .userDefaultTestValue,
            userDefaults: userDefaults,
            defaultValue: defaultValue
        )
    }
}
