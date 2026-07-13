# Changelog

All notable changes to the `m` plugin are documented in this file.

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
