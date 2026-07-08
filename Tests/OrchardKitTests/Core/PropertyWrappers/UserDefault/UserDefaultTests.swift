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

    @Test("UserDefaults stores supported scalar values")
    func userDefaultsStoresSupportedScalarValues() throws {
        let userDefaults = try #require(makeUserDefaults())
        let date = Date(timeIntervalSince1970: 1_234)
        let data = Data([1, 2, 3])

        userDefaults[.userDefaultTestValue] = "stored"
        userDefaults[.boolTestValue] = true
        userDefaults[.intTestValue] = 42
        userDefaults[.floatTestValue] = 1.5
        userDefaults[.doubleTestValue] = 2.5
        userDefaults[.dateTestValue] = date
        userDefaults[.dataTestValue] = data

        #expect(userDefaults[.userDefaultTestValue] == "stored")
        #expect(userDefaults[.boolTestValue] == true)
        #expect(userDefaults[.intTestValue] == 42)
        #expect(userDefaults[.floatTestValue] == 1.5)
        #expect(userDefaults[.doubleTestValue] == 2.5)
        #expect(userDefaults[.dateTestValue] == date)
        #expect(userDefaults[.dataTestValue] == data)
    }

    @Test("Unsupported UserDefaults values fail to compile")
    func unsupportedUserDefaultsValuesFailToCompile() throws {
        let packageDirectory = try #require(packageDirectoryURL())
        let result = try buildCompileProbe(
            packageDirectory: packageDirectory,
            source: """
            import Foundation
            import OrchardKit

            struct Unsupported {}

            let key = UserDefaults.Key<Unsupported>(
                name: "unsupported"
            )
            _ = key
            """
        )

        #expect(result.exitCode != 0)
        #expect(
            result.output.contains(
                "'init(name:)' is unavailable"
            )
        )
        #expect(result.output.contains("supports only String, Bool, Int, Float, Double, Data, and Date"))
    }

    private func makeUserDefaults() -> UserDefaults? {
        let suiteName = "UserDefaultTests.\(UUID().uuidString)"

        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func buildCompileProbe(
        packageDirectory: URL,
        source: String
    ) throws -> (exitCode: Int32, output: String) {
        let fileManager = FileManager.default
        let probeDirectory = fileManager.temporaryDirectory.appendingPathComponent(
            "OrchardKitCompileProbe-\(UUID().uuidString)"
        )
        let sourcesDirectory = probeDirectory
            .appendingPathComponent("Sources")
            .appendingPathComponent("CompileProbe")

        try fileManager.createDirectory(
            at: sourcesDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? fileManager.removeItem(at: probeDirectory)
        }

        let packageManifest = """
        // swift-tools-version: 6.2
        import PackageDescription

        let package = Package(
            name: "CompileProbe",
            platforms: [
                .macOS(.v12),
            ],
            dependencies: [
                .package(path: "\(swiftStringLiteral(packageDirectory.path))"),
            ],
            targets: [
                .executableTarget(
                    name: "CompileProbe",
                    dependencies: [
                        .product(
                            name: "OrchardKit",
                            package: "OrchardKit"
                        ),
                    ]
                ),
            ]
        )
        """

        try packageManifest.write(
            to: probeDirectory.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )
        try source.write(
            to: sourcesDirectory.appendingPathComponent("main.swift"),
            atomically: true,
            encoding: .utf8
        )

        let outputPipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", "build"]
        process.currentDirectoryURL = probeDirectory
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(decoding: outputData, as: UTF8.self)

        return (process.terminationStatus, output)
    }

    private func packageDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

        while true {
            let packageManifest = directory.appendingPathComponent("Package.swift")
            if fileManager.fileExists(atPath: packageManifest.path) {
                return directory
            }

            let parentDirectory = directory.deletingLastPathComponent()
            if parentDirectory.path == directory.path {
                return nil
            }

            directory = parentDirectory
        }
    }

    private func swiftStringLiteral(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
