import Foundation

public final class FileLogRoute: LogRoute, LogFileLocationProviding {
    public let logFileURL: URL
    public let maxBytes: Int
    public let routeType: LogRouteType

    private let fileManager: FileManager
    private let writeQueue: DispatchQueue

    private var fileHandle: FileHandle?
    private var currentSize: Int = 0

    public init(
        fileURL: URL,
        routeType: LogRouteType = .file,
        maxBytes: Int = 262_144,
        fileManager: FileManager = .default
    ) {
        precondition(maxBytes > 0, "maxBytes must be greater than zero.")

        self.logFileURL = fileURL
        self.routeType = routeType
        self.maxBytes = maxBytes
        self.fileManager = fileManager
        self.writeQueue = DispatchQueue(
            label: "com.orchardkit.logging.file-route",
            qos: .utility
        )

        writeQueue.sync {
            prepareFileIfNeeded()
        }
    }

    public static func defaultFileURL(
        fileName: String = "orchardkit-logs.txt",
        fileManager: FileManager = .default
    ) -> URL {
        let baseDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return baseDirectory.appendingPathComponent(fileName)
    }

    public func isEnabled(for level: LogLevel) -> Bool {
        level == .info || level == .error
    }

    public func log(_ message: LogMessage) {
        if let data = "\(message.renderedMessage)\n".data(using: .utf8) {
            let workItem = DispatchWorkItem { [weak self] in
                self?.append(data)
            }
            writeQueue.async(execute: workItem)
        }
    }

    func flushForTesting() {
        writeQueue.sync {}
    }

    private func append(_ data: Data) {
        if data.count > maxBytes {
            return
        }

        if currentSize + data.count > maxBytes {
            truncateFile()
        }

        if fileHandle == nil {
            openFileHandle()
        }

        if let fileHandle {
            do {
                try fileHandle.write(contentsOf: data)
                currentSize += data.count
            } catch {
                closeFileHandle()
            }
        }
    }

    private func prepareFileIfNeeded() {
        createParentDirectoryIfNeeded()
        createFileIfNeeded()
        currentSize = existingFileSize()
        openFileHandle()
    }

    private func createParentDirectoryIfNeeded() {
        let parentDirectory = logFileURL.deletingLastPathComponent()

        if !fileManager.fileExists(atPath: parentDirectory.path) {
            try? fileManager.createDirectory(
                at: parentDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func createFileIfNeeded() {
        if !fileManager.fileExists(atPath: logFileURL.path) {
            _ = fileManager.createFile(
                atPath: logFileURL.path,
                contents: Data()
            )
        }
    }

    private func existingFileSize() -> Int {
        let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path)
        let fileSize = attributes?[.size] as? NSNumber

        return fileSize?.intValue ?? 0
    }

    private func openFileHandle() {
        do {
            let handle = try FileHandle(forWritingTo: logFileURL)
            try handle.seekToEnd()
            fileHandle = handle
        } catch {
            fileHandle = nil
        }
    }

    private func closeFileHandle() {
        if let fileHandle {
            try? fileHandle.close()
            self.fileHandle = nil
        }
    }

    private func truncateFile() {
        closeFileHandle()
        try? Data().write(
            to: logFileURL,
            options: .atomic
        )
        currentSize = 0
        openFileHandle()
    }
}
