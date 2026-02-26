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
