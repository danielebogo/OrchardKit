import Testing
@testable import OrchardKit

@Test("OrchardKit umbrella module is exposed")
func orchardKitModuleIsAvailable() {
    #expect(String(describing: OrchardKit.self) == "OrchardKit")
}
