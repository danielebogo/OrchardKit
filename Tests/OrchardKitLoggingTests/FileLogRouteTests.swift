import Foundation
import Testing
@testable import OrchardKitLogging

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
    let fileRoute = FileLogRoute(
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
    let fileRoute = FileLogRoute(
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

@Test("FileLogRoute supports custom file name initializer")
func fileLogRouteSupportsCustomFileNameInitializer() {
    let fileManager = FileManager.default
    let fileName = "orchardkit-\(UUID().uuidString).log"
    let fileRoute = FileLogRoute(
        fileName: fileName,
        maxBytes: 512,
        fileManager: fileManager
    )
    defer {
        try? fileManager.removeItem(at: fileRoute.logFileURL)
    }

    #expect(fileRoute.logFileURL.lastPathComponent == fileName)
}
