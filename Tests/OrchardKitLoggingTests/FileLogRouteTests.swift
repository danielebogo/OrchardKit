import Foundation
import Testing
@testable import OrchardKitLogging

// Failure modes:
// - Parent directory creation fails
// - Parent path exists as a file
// - Log file creation fails
// - Writable file handle cannot be opened

@Test("FileLogRoute writes only info and error logs")
func fileLogRouteWritesOnlyInfoAndErrorLogs() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let fileRoute = try FileLogRoute(
        fileURL: fileURL,
        maxBytes: 4_096,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    logger.log(
        .debug,
        "debug"
    )
    logger.log(
        .info,
        "info"
    )
    logger.log(
        .error,
        "error"
    )
    logger.log(
        .warning,
        "warning"
    )
    fileRoute.flushForTesting()

    let contents = try String(
        contentsOf: fileURL,
        encoding: .utf8
    )

    #expect(contents.contains("[INFO] info"))
    #expect(contents.contains("[ERROR] error"))
    #expect(!contents.contains("[DEBUG]"))
    #expect(!contents.contains("[WARNING]"))
}

@Test("FileLogRoute skips low verbosity logs by default")
func fileLogRouteSkipsLowVerbosityLogsByDefault() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let fileRoute = try FileLogRoute(
        fileURL: fileURL,
        maxBytes: 4_096,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    logger.log(
        .info,
        "default info"
    )
    logger.log(
        .info,
        "low info",
        verbosity: .low
    )
    fileRoute.flushForTesting()

    let contents = try String(
        contentsOf: fileURL,
        encoding: .utf8
    )

    #expect(contents.contains("[INFO] default info"))
    #expect(!contents.contains("[INFO] low info"))
}

@Test("FileLogRoute can include low verbosity logs")
func fileLogRouteCanIncludeLowVerbosityLogs() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let fileRoute = try FileLogRoute(
        fileURL: fileURL,
        verbosity: .low,
        maxBytes: 4_096,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    logger.log(
        .info,
        "default info"
    )
    logger.log(
        .info,
        "low info",
        verbosity: .low
    )
    fileRoute.flushForTesting()

    let contents = try String(
        contentsOf: fileURL,
        encoding: .utf8
    )

    #expect(contents.contains("[INFO] default info"))
    #expect(contents.contains("[INFO] low info"))
}

@Test("FileLogRoute caps file size")
func fileLogRouteCapsFileSize() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let maxBytes = 128
    let fileRoute = try FileLogRoute(
        fileURL: fileURL,
        maxBytes: maxBytes,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    for index in 0..<30 {
        logger.log(
            .info,
            "payload-\(index)-abcdefghijklmnopqrstuvwxyz"
        )
    }
    fileRoute.flushForTesting()

    let attributes = try #require(
        try? fileManager.attributesOfItem(atPath: fileURL.path)
    )
    let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
    #expect(fileSize <= maxBytes)
}

@Test(
    "FileLogRoute keeps the next writable message after truncation",
    .bug("https://github.com/danielebogo/OrchardKit/issues/4")
)
func fileLogRouteKeepsNextWritableMessageAfterTruncation() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    func readLogContents() throws -> String {
        try String(
            contentsOf: fileURL,
            encoding: .utf8
        )
    }

    let firstMessage = LogMessage(
        level: .info,
        message: "before-truncation-marker-abcdefghijklmnopqrstuvwxyz",
        fileID: "FileLogRouteTests.swift",
        function: "fileLogRouteKeepsNextWritableMessageAfterTruncation()",
        line: 1
    )
    let sentinelMessage = LogMessage(
        level: .info,
        message: "after-truncation-sentinel",
        fileID: "FileLogRouteTests.swift",
        function: "fileLogRouteKeepsNextWritableMessageAfterTruncation()",
        line: 2
    )
    let firstByteCount = "\(firstMessage.renderedMessage)\n".utf8.count
    let sentinelByteCount = "\(sentinelMessage.renderedMessage)\n".utf8.count
    let fileRoute = try FileLogRoute(
        fileURL: fileURL,
        maxBytes: firstByteCount + sentinelByteCount - 1,
        fileManager: fileManager
    )

    fileRoute.log(firstMessage)
    fileRoute.flushForTesting()

    let initialContents = try readLogContents()

    #expect(initialContents.contains("before-truncation-marker"))

    fileRoute.log(sentinelMessage)
    fileRoute.flushForTesting()

    let truncatedContents = try readLogContents()

    #expect(truncatedContents.contains("after-truncation-sentinel"))
    #expect(truncatedContents.contains("before-truncation-marker") == false)
}

@Test("FileLogRoute fails when parent path is not a directory")
func fileLogRouteFailsWhenParentPathIsNotDirectory() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let parentFileURL = directoryURL.appendingPathComponent("not-a-directory")
    _ = fileManager.createFile(
        atPath: parentFileURL.path,
        contents: Data()
    )
    let fileURL = parentFileURL.appendingPathComponent("orchardkit-file-route.log")
    let expectedURL = fileURL.deletingLastPathComponent()
    expectFileLogRouteInitializationFailure(
        expectedDescription: "parentPathIsNotDirectory for \(expectedURL.path)"
    ) {
        _ = try FileLogRoute(
            fileURL: fileURL,
            maxBytes: 4_096,
            fileManager: fileManager
        )
    } matches: { error in
        if case .parentPathIsNotDirectory(let url) = error {
            return url == expectedURL
        }

        return false
    }
}

@Test("FileLogRoute fails when parent directory creation fails")
func fileLogRouteFailsWhenParentDirectoryCreationFails() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let expectedURL = fileURL.deletingLastPathComponent()
    let fileSystem = FileLogRouteFileSystem(
        fileManager: fileManager,
        createDirectory: { _, _ in
            throw CocoaError(.fileWriteNoPermission)
        }
    )

    expectFileLogRouteInitializationFailure(
        expectedDescription: "failedToCreateParentDirectory for \(expectedURL.path)"
    ) {
        _ = try FileLogRoute(
            fileURL: fileURL,
            maxBytes: 4_096,
            fileSystem: fileSystem,
            writeQueue: DispatchQueue(label: "FileLogRouteTests.parent-directory-failure")
        )
    } matches: { error in
        if case .failedToCreateParentDirectory(let url, _) = error {
            return url == expectedURL
        }

        return false
    }
}

@Test("FileLogRoute fails when file creation fails")
func fileLogRouteFailsWhenFileCreationFails() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let fileSystem = FileLogRouteFileSystem(
        fileManager: fileManager,
        createFile: { _, _ in false }
    )

    expectFileLogRouteInitializationFailure(
        expectedDescription: "failedToCreateFile for \(fileURL.path)"
    ) {
        _ = try FileLogRoute(
            fileURL: fileURL,
            maxBytes: 4_096,
            fileSystem: fileSystem,
            writeQueue: DispatchQueue(label: "FileLogRouteTests.file-creation-failure")
        )
    } matches: { error in
        if case .failedToCreateFile(let url) = error {
            return url == fileURL
        }

        return false
    }
}

@Test("FileLogRoute fails when file handle cannot open")
func fileLogRouteFailsWhenFileHandleCannotOpen() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let fileSystem = FileLogRouteFileSystem(
        fileManager: fileManager,
        openFileHandle: { _ in
            throw CocoaError(.fileWriteNoPermission)
        }
    )

    expectFileLogRouteInitializationFailure(
        expectedDescription: "failedToOpenFile for \(fileURL.path)"
    ) {
        _ = try FileLogRoute(
            fileURL: fileURL,
            maxBytes: 4_096,
            fileSystem: fileSystem,
            writeQueue: DispatchQueue(label: "FileLogRouteTests.file-open-failure")
        )
    } matches: { error in
        if case .failedToOpenFile(let url, _) = error {
            return url == fileURL
        }

        return false
    }
}

@Test("FileLogRoute drops writes when pending limit is reached")
func fileLogRouteDropsWritesWhenPendingLimitIsReached() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let writeQueue = DispatchQueue(label: "FileLogRouteTests.suspended")
    let fileRoute = try FileLogRoute(
        fileURL: fileURL,
        maxBytes: 4_096,
        maxPendingWrites: 1,
        fileManager: fileManager,
        writeQueue: writeQueue
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    writeQueue.suspend()
    logger.log(
        .info,
        "first"
    )
    logger.log(
        .info,
        "second"
    )
    writeQueue.resume()
    fileRoute.flushForTesting()

    let contents = try String(
        contentsOf: fileURL,
        encoding: .utf8
    )

    #expect(contents.contains("[INFO] first"))
    #expect(!contents.contains("[INFO] second"))
}

@Test("FileLogRoute supports custom file name initializer")
func fileLogRouteSupportsCustomFileNameInitializer() throws {
    let fileManager = FileManager.default
    let fileName = "orchardkit-\(UUID().uuidString).log"
    let fileRoute = try FileLogRoute(
        fileName: fileName,
        maxBytes: 512,
        fileManager: fileManager
    )
    defer {
        try? fileManager.removeItem(at: fileRoute.logFileURL)
    }

    #expect(fileRoute.logFileURL.lastPathComponent == fileName)
}

/// Asserts that `FileLogRoute` initialization fails with the expected route error.
///
/// - Parameters:
///   - expectedDescription: A readable description of the expected error case and context.
///   - operation: The initialization operation expected to throw.
///   - expectedErrorMatches: A matcher that verifies the exact error case and associated values.
private func expectFileLogRouteInitializationFailure(
    expectedDescription: String,
    operation: () throws -> Void,
    matches expectedErrorMatches: (FileLogRouteError) -> Bool
) {
    do {
        try operation()
        Issue.record("Expected \(expectedDescription).")
    } catch let error as FileLogRouteError {
        #expect(
            expectedErrorMatches(error),
            "Expected \(expectedDescription), got \(error)."
        )
    } catch {
        Issue.record("Expected \(expectedDescription), got \(error).")
    }
}
