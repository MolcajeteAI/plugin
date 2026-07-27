# Changelog

All notable changes to the `m` plugin are documented in this file.

## 3.4.0 — 2026-07-24

### Changed

- **Tests, comments, and code now describe only current behavior.** New Principle 1.5 ("Test only current behavior") and 5.5 ("Comments and code describe only current behavior") in the `principles` skill make the rule explicit: assert new behavior directly, never write a test proving a removed capability is gone, and never leave a comment narrating what the code used to do. New functional requirements and behaviorally-observable non-functional requirements (authz, validation, error handling, idempotency) each get a positive test; NFRs not reachable through a driver port stay spec-only.
- **`/m:build` reconciles a dirty slice before rewriting it.** When a slice is `dirty` because its UC changed via `/m:fix`, `/m:change`, or `/m:spec`, the build now deletes test cases, assertions, comments, and code for scenarios the spec no longer contains; rewrites changed scenarios to the new expected values; and adds tests for new FR / behavioral NFR. A new "Orphaned assertion / dead behavior" gap class in the `testing` skill and the build's coverage loop makes stale-artifact deletion proactive rather than coverage-driven.
- **`/m:plan` reconciles a superseded slice's `covers` against the current UC** when marking it `dirty` — dropping `SC`/`FR` IDs the spec no longer contains and placing new ones — so a dropped ID signals "delete its tests and code," never "test that the behavior is gone."
- **`/m:change` and `/m:fix` spec edits replace, they do not annotate.** The commands now state that a spec edit replaces the old text (no "previously X" annotations; history lives in the changelog `reason`), and `/m:fix` reasons state the expected behavior positively so `/m:plan` writes a test of the correct behavior rather than one that merely proves the bug is absent.

## 3.3.0 — 2026-07-12

### Changed

- **Multi-module use cases now share a single UC-XXXX ID across every module the capability appears in.** Each module still keeps its own module-scoped `UC-XXXX-{slug}.md` — actor, trigger, scenarios, and side effects written from that module's perspective — mirroring the pattern features have used since 3.0. UC name and slug may differ per module while the ID stays constant.
- `/m:spec`, `/m:change`, `/m:fix`, `/m:cover`, and `/m:plan` now fan out across every module-instance of a UC. A change or fix against a shared UC-XXXX resolves to the set of module-instances first; the user can narrow the fan-out per event.
- **`uc-log` CHANGELOG entries carry an optional `modules:` token** listing every module-instance the event applied to. The token is omitted for single-module UCs and appears whenever a UC has 2+ module-instances. Multi-module fan-outs share timestamp and reason text across peer instances but each writes to its own CHANGELOG.md.
- `/m:plan`'s `plan.md` groups slices under `## FEAT-{id}-{slug} — {module}` headings when a shared UC exists in multiple modules, so the reader can see which module each slice targets.

### Design rationale

Prior to 3.3, `/m:spec` handled multi-module features correctly (one FEAT-XXXX across modules with module-scoped REQUIREMENTS.md) but stopped at the feature level — use cases were treated as strictly per-module. In practice, the same capability across modules ended up either spec'd in only one module (silently dropped) or spec'd in both with different UC IDs (silently duplicated). Two paths were considered:

- **Option A — Global UC file both modules reference.** Rejected. Readers would open two files (the global doc plus a per-module addendum) and cross-module state would drift between them.
- **Option B — Same UC ID, module-scoped contents.** Chosen. Extends the pattern features already use. Every module-instance stands alone, no cross-file reading required, and the shared ID makes cross-module reporting trivial (all writes fan out to the same UC-XXXX). The `modules:` token in CHANGELOG.md preserves fan-out visibility from any single module's perspective.

Single-module projects are unaffected. Existing multi-module projects that already used distinct UC IDs per module keep working; the shared-ID pattern applies going forward.
