import Foundation

public final class FileLogRoute: LogRoute, LogFileLocationProviding {
    public let logFileURL: URL
    public let routeType: LogRouteType
    public let maxBytes: Int
    public let verbosity: LogVerbosity

    private let fileManager: FileManager
    private let writeQueue: DispatchQueue
    private let writeQueueKey = DispatchSpecificKey<Void>()

    private var fileHandle: FileHandle?
    private var currentSize: Int = 0

    public init(
        fileURL: URL,
        routeType: LogRouteType = .file,
        verbosity: LogVerbosity = .default,
        maxBytes: Int = 262_144,
        fileManager: FileManager = .default
    ) {
        precondition(maxBytes > 0, "maxBytes must be greater than zero.")

        self.logFileURL = fileURL
        self.routeType = routeType
        self.verbosity = verbosity
        self.maxBytes = maxBytes
        self.fileManager = fileManager
        self.writeQueue = DispatchQueue(
            label: "com.orchardkit.logging.file-route",
            qos: .utility
        )
        self.writeQueue.setSpecific(
            key: writeQueueKey,
            value: ()
        )

        writeQueue.sync {
            prepareFileIfNeeded()
        }
    }

    public convenience init(
        fileName: String = "orchardkit-logs.txt",
        routeType: LogRouteType = .file,
        verbosity: LogVerbosity = .default,
        maxBytes: Int = 262_144,
        fileManager: FileManager = .default
    ) {
        self.init(
            fileURL: Self.defaultFileURL(
                fileName: fileName,
                fileManager: fileManager
            ),
            routeType: routeType,
            verbosity: verbosity,
            maxBytes: maxBytes,
            fileManager: fileManager
        )
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

    public func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        self.verbosity.includes(verbosity)
            && (level == .info || level == .error)
    }

    public func log(_ message: LogMessage) {
        let workItem = DispatchWorkItem { [weak self] in
            self?.write(message)
        }

        writeQueue.async(execute: workItem)
    }

    func flushForTesting() {
        if DispatchQueue.getSpecific(key: writeQueueKey) != nil {
            return
        }

        writeQueue.sync {}
    }

    private func write(_ message: LogMessage) {
        let renderedMessage = "\(message.renderedMessage)\n"

        if let data = renderedMessage.data(using: .utf8) {
            append(data)
        }
    }

    private func append(_ data: Data) {
        if data.count > maxBytes {
            return
        }

        if currentSize + data.count > maxBytes {
            let truncateSucceeded = truncateFile()
            if !truncateSucceeded {
                return
            }

            if currentSize + data.count > maxBytes {
                return
            }
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
                currentSize = existingFileSize()
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

    private func truncateFile() -> Bool {
        closeFileHandle()

        do {
            try Data().write(
                to: logFileURL,
                options: .atomic
            )
        } catch {
            currentSize = existingFileSize()
            openFileHandle()
            return false
        }

        currentSize = existingFileSize()
        openFileHandle()
        return true
    }
}
