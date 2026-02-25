# Logger Skeleton Plan

## Tasks
- [x] Review existing package structure and define logger API skeleton.
- [x] Update `Package.swift` to add a dedicated logging module target and test coverage wiring.
- [x] Implement protocol-driven logger router primitives in a new logging module.
- [x] Implement the first route backed by `OSLog`.
- [x] Add Swift Testing-based unit tests for routing behavior and `OSLog` level mapping.
- [x] Run package tests and document verification results.

## Review
- `swift test` passes after adding the `OrchardKitLogging` module and logger routes.
- Logger routing behavior is covered (fan-out to multiple routes, runtime route registration).
- `OSLogRoute` coverage includes parameterized level-to-`OSLogType` mapping and rendered payload forwarding.

# Logger Performance + Platform Support Plan

## Tasks
- [x] Add explicit package platforms for iOS/iPadOS (via iOS), tvOS, and macOS in `Package.swift`.
- [x] Make logger route handling thread-safe with low lock contention.
- [x] Add route-level enablement checks to skip payload creation when no route will log.
- [x] Optimize `OSLogRoute` to report enablement using `OSLog.isEnabled(type:)`.
- [x] Add Swift Testing coverage for route enablement short-circuit behavior and thread-safe routing updates.
- [x] Run `swift test` and document verification results.

## Review
- Package platforms are now explicitly declared for `.iOS(.v15)`, `.tvOS(.v15)`, and `.macOS(.v12)`; iPadOS is covered by iOS in SwiftPM.
- Logger now short-circuits before building payloads when every route is disabled for the requested level.
- Logger route access is lock-protected and snapshot-based, reducing contention while remaining thread-safe.
- `OSLogRoute` now reports enablement through `OSLog.isEnabled(type:)`.
- `swift test` passes with 7 tests, including parameterized `OSLog` mapping and route-enablement tests.
- SDK-pinned builds pass for iOS simulator and tvOS simulator via `swift build --sdk ... --triple ...`; iPadOS is covered by the iOS platform declaration in SwiftPM.

# OSLog Modernization Plan

## Tasks
- [x] Review the SwiftLee OSLog article and extract relevant API improvements for this codebase.
- [x] Migrate `OSLogRoute` from C-style `os_log` usage to modern unified logging `Logger` API.
- [x] Preserve route-level enablement checks and existing log-level mapping behavior.
- [x] Update/adjust Swift Testing coverage if needed for the migrated writer behavior.
- [x] Run `swift test` and cross-platform iOS/tvOS simulator build checks.
- [x] Document verification results.

## Review
- Adopted modern unified logging writer by replacing C-style `os_log` calls with `os.Logger.log(level:_:)`.
- Kept route-level fast-path checks via `OSLog.isEnabled(type:)`, preserving prior behavior and performance guardrails.
- Maintained the existing public logging API; migration stayed internal to `OSLogRoute`.
- `swift test` passes.
- iOS simulator SDK build passes (`arm64-apple-ios15.0-simulator`).
- tvOS simulator SDK build passes (`arm64-apple-tvos15.0-simulator`).

# System Logger Levels Alignment Plan

## Tasks
- [x] Expand `LogLevel` to match the requested system-style list: notice, info, debug, trace, warning, error, fault, critical.
- [x] Update `OSLogRoute` level mapping so enablement and writes map consistently to supported `OSLogType`s.
- [x] Update Swift Testing cases to cover the expanded level list and revised mappings.
- [x] Run `swift test` and iOS/tvOS simulator SDK build checks.
- [x] Document review results.

## Review
- `LogLevel` now reflects the requested system-style set: notice/info/debug/trace/warning/error/fault/critical.
- Mapping now aligns to supported `OSLogType` buckets:
  - `notice -> .default`
  - `info -> .info`
  - `debug -> .debug`
  - `trace -> .debug`
  - `warning -> .error`
  - `error -> .error`
  - `fault -> .fault`
  - `critical -> .fault`
- Swift Testing coverage expanded to 8 parameterized cases for mapping and route enablement.
- `swift test` passes.
- iOS simulator SDK build passes (`arm64-apple-ios15.0-simulator`).
- tvOS simulator SDK build passes (`arm64-apple-tvos15.0-simulator`).

# File Route Plan

## Tasks
- [x] Add a new file route that only persists `.info` and `.error` logs.
- [x] Enforce a configurable max file size to keep payload bounded for API upload.
- [x] Keep write-path overhead low for heavy logging scenarios.
- [x] Add router accessors on `Logger` to retrieve the stored log file path/URL.
- [x] Add Swift Testing coverage for filtering, size cap behavior, and path retrieval.
- [x] Run `swift test` plus iOS/tvOS simulator SDK builds.

## Review
- Added `FileLogRoute` with route filtering limited to `.info` and `.error`.
- Added bounded file-size behavior via `maxBytes`; route truncates and restarts the file when the next append would exceed the cap.
- Kept write overhead low with an internal utility-priority serial queue, a persistent file handle, and cached current file size tracking.
- Added router path retrieval APIs on `Logger`: `firstLogFileURL()` and `firstLogFilePath()`.
- Added Swift Testing coverage for: info/error-only filtering, size cap enforcement, and router path retrieval.
- Verification passed:
  - `swift test`
  - iOS simulator SDK build (`arm64-apple-ios15.0-simulator`)
  - tvOS simulator SDK build (`arm64-apple-tvos15.0-simulator`)

# Route Type Lookup Plan

## Tasks
- [x] Add enum-based route identification so any `LogRoute` has a route type.
- [x] Assign concrete route types for `OSLogRoute` and `FileLogRoute`.
- [x] Add typed lookup APIs to retrieve file URL/path by route type rather than first route only.
- [x] Keep existing first-file helper APIs for backward compatibility.
- [x] Add Swift Testing coverage for typed lookups.
- [x] Run `swift test` plus iOS/tvOS simulator SDK builds.

## Review
- Added `LogRouteType` enum with `.osLog`, `.file`, and `.custom(String)`.
- Extended `LogRoute` with `routeType`; default identifies custom routes via `.custom(typeName)`.
- Set concrete route types:
  - `OSLogRoute.routeType == .osLog`
  - `FileLogRoute.routeType` defaults to `.file` and can be overridden via initializer for custom typed lookup.
- Added typed retrieval APIs on `Logger`:
  - `logFileURL(for:)`
  - `logFilePath(for:)`
- Preserved existing `firstLogFileURL()`/`firstLogFilePath()` by routing them through `.file`.
- Added tests validating typed lookup and backward-compatible helper behavior.
- Verification passed:
  - `swift test`
  - iOS simulator SDK build (`arm64-apple-ios15.0-simulator`)
  - tvOS simulator SDK build (`arm64-apple-tvos15.0-simulator`)
