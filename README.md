# OrchardKit

OrchardKit is a Swift Package that groups reusable modules for Apple-platform apps.

Current library products:
- `OrchardKit`
- `OrchardKitLogging`

Supported platforms:
- iOS 15+
- tvOS 15+
- macOS 12+

## OrchardKitLogging

`OrchardKitLogging` is a simple route-based logger.

The logger itself does one job:
- build a `LogMessage`
- send it to every route enabled for that level

A route decides:
- whether a level should be handled
- where the message should go

Out of the box the package includes:
- `OSLogRoute` for Apple unified logging
- `FileLogRoute` for writing support logs to a text file

## Add The Package

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/danielebogo/OrchardKit.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(
                    name: "OrchardKitLogging",
                    package: "OrchardKit"
                )
            ]
        )
    ]
)
```

Import the logging module where you need it:

```swift
import OrchardKitLogging
```

## Create A Logger

```swift
import OrchardKitLogging

let logger = Logger(
    routes: [
        OSLogRoute(
            subsystem: "com.example.myapp",
            category: "app"
        ),
        FileLogRoute(
            fileName: "support.log"
        )
    ]
)
```

You can also start empty and add routes later:

```swift
let logger = Logger()

logger.addRoute(
    OSLogRoute(
        subsystem: "com.example.myapp",
        category: "network"
    )
)
```

## Write Logs

```swift
logger.log(.notice, "App launched")
logger.log(.info, "Sync started")
logger.log(.debug, "Prepared request payload")
logger.log(.trace, "Entered refresh pipeline")
logger.log(.warning, "Retrying request")
logger.log(.error, "Download failed")
logger.log(.fault, "Database corruption detected")
logger.log(.critical, "Startup aborted")
```

You can attach metadata too:

```swift
logger.log(
    .error,
    "Upload failed",
    metadata: [
        "episodeId": "123",
        "retry": "1"
    ]
)
```

Each log becomes a `LogMessage` with:
- level
- message
- metadata
- `fileID`
- `function`
- `line`
- timestamp

Those values are filled automatically unless you override them.

## File Logging

`FileLogRoute` is intended for support-style logs.

Current behavior:
- writes only `.info` and `.error`
- writes on a background utility queue
- stores logs as UTF-8 text
- truncates the file if the next write would exceed `maxBytes`

Create a file route with the default location:

```swift
let fileRoute = FileLogRoute(
    fileName: "support.log",
    maxBytes: 262_144
)
```

Or provide the full URL yourself:

```swift
let fileURL = FileManager.default
    .temporaryDirectory
    .appendingPathComponent("support.log")

let fileRoute = FileLogRoute(
    fileURL: fileURL,
    routeType: .custom("support-upload")
)
```

Default filename:
- `orchardkit-logs.txt`

Default directory:
- caches directory when available
- temporary directory as fallback

## Retrieve The File Path

If you need to upload or share the file later, ask the logger for the path of a specific route type:

```swift
let logger = Logger(routes: [fileRoute])

let defaultPath = logger.logFilePath(for: .file)
let customPath = logger.logFilePath(for: .custom("support-upload"))
let firstPath = logger.firstLogFilePath()
```

Use custom route types when you have more than one file route.

## OSLog Route

`OSLogRoute` forwards logs to Apple unified logging.

```swift
let route = OSLogRoute(
    subsystem: "com.example.myapp",
    category: "playback"
)
```

Level mapping:
- `notice` -> `.default`
- `info` -> `.info`
- `debug` -> `.debug`
- `trace` -> `.debug`
- `warning` -> `.error`
- `error` -> `.error`
- `fault` -> `.fault`
- `critical` -> `.fault`

## Create A Custom Route

Conform to `LogRoute` to send messages somewhere else.

```swift
struct ConsoleRoute: LogRoute {
    let routeType: LogRouteType = .custom("console")

    func isEnabled(for level: LogLevel) -> Bool {
        level != .trace
    }

    func log(_ message: LogMessage) {
        print(message.renderedMessage)
    }
}
```

Then use it like any other route:

```swift
let logger = Logger(
    routes: [
        ConsoleRoute()
    ]
)
```

## Performance Notes

A few design points help keep the logger lightweight:
- the logger only builds a `LogMessage` if at least one route is enabled for that level
- routes are evaluated from a snapshot, so adding routes does not interfere with log fan-out
- file I/O stays off the caller thread
- the router itself stays simple and does not coordinate routes with each other

## Testing

Run the package tests with:

```bash
swift test
```
