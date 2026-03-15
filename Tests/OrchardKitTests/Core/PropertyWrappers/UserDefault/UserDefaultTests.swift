import Foundation
import Testing
@testable import OrchardKit

@Suite("UserDefault")
struct UserDefaultTests {
    @Test("UserDefault reads a stored value")
    func userDefaultReadsStoredValue() throws {
        let userDefaults = try #require(makeUserDefaults())
        userDefaults[.userDefaultTestValue] = "stored"

        let subject = UserDefaultTestSubject(userDefaults: userDefaults)

        #expect(subject.value == "stored")
    }

    @Test("UserDefault returns its default value")
    func userDefaultReturnsDefaultValue() throws {
        let userDefaults = try #require(makeUserDefaults())
        let subject = UserDefaultTestSubject(
            userDefaults: userDefaults,
            defaultValue: "fallback"
        )

        #expect(subject.value == "fallback")
    }

    @Test("UserDefault writes through to UserDefaults")
    func userDefaultWritesThroughToUserDefaults() throws {
        let userDefaults = try #require(makeUserDefaults())
        var subject = UserDefaultTestSubject(userDefaults: userDefaults)

        subject.value = "updated"

        #expect(userDefaults[.userDefaultTestValue] == "updated")
    }

    @Test("Projected value can delete the stored value")
    func projectedValueDeletesStoredValue() throws {
        let userDefaults = try #require(makeUserDefaults())
        var subject = UserDefaultTestSubject(userDefaults: userDefaults)
        subject.value = "stored"

        subject.$value.delete()

        #expect(userDefaults[.userDefaultTestValue] == nil)
    }

    private func makeUserDefaults() -> UserDefaults? {
        let suiteName = "UserDefaultTests.\(UUID().uuidString)"

        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
