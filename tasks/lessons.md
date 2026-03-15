# Lessons Learned

## 2026-02-24
- Avoid defaulting to `@unchecked Sendable` for production types just to satisfy test-time concurrency warnings.
- If a warning comes from a stress-test shape (`@Sendable` closure captures), prefer refactoring the test strategy before weakening type-safety guarantees.
- Keep synchronization scoped to real shared mutable state (the logger route registry), and do not add synchronization inside `OSLogRoute` unless a concrete issue demands it.

## 2026-02-25
- When users ask for system-aligned log levels, mirror the full requested vocabulary in `LogLevel` first, then document and test how those levels collapse into the limited `OSLogType` buckets.
- Follow AGENTS style rules strictly for control flow: avoid `guard !...` double negation for simple empty/non-empty checks and prefer direct `if` statements.
- Enforce AGENTS function-signature formatting: when declarations have 3+ parameters, use multiline declaration style with one parameter per line.
- Do not over-interpret the multiline exceptions; default to multiline for multi-parameter declarations/calls in touched files unless a case is truly trivial.
- Keep initializer declarations in touched logging files visually consistent with the chosen multiline style, even when only two parameters are present.
- Apply the same multiline style to multi-parameter call sites in touched files (not only declarations), including short two-argument calls when consistency is requested.
- When multiple routes can expose similar capabilities (like file paths), avoid “first route” lookups as the primary API and provide enum-typed route selection.
- After a review pass, implement every requested finding unless explicitly excluded by the user, and reflect each fix with targeted tests where feasible.
- For logger routers, prefer simple fan-out design and avoid cross-route synchronization that can create deadlocks or throughput regressions.
- For route APIs, expose simple consumer-facing initializers for common setup (like file-name injection) while keeping explicit low-level options.
- During file-organization refactors, keep each public protocol/type in its own focused file when the user asks for clearer structure.

## 2026-03-03
- Before citing a repo or global `AGENTS.md`, verify the actual file path instead of relying on injected context or memory.

## 2026-03-15
- When porting shared dependency helpers into a Swift 6 package, treat mutable static container state as a concurrency boundary from the start and protect it explicitly instead of relying on plain `static var`.
- In test targets, avoid adding an extra grouping folder when the existing feature path already provides enough context and the user prefers flatter test support layout.
- When testing property wrappers that depend on injected runtime values, initialize the backing storage in `init` instead of trying to reference instance members from the wrapper attribute.
