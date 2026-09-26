---
name: pragmatic-rust-guidelines
description: Pragmatic Rust design guidelines covering universal idioms, API UX, resilience, performance, correctness, macros, and FFI. Use when writing, reviewing, or refactoring Rust code to ensure safety, efficiency, and maintainability.
---

# Pragmatic Rust Guidelines

A comprehensive collection of pragmatic design guidelines helping Rust developers and AI agents produce idiomatic, safe, and high-performance code that scales.

## When to Use This Skill
- **Writing new Rust code**: Refer to naming conventions, type modeling, and ergonomic API design patterns.
- **Code reviews & refactoring**: Check for anti-patterns, unsoundness, unhandled panics, and allocation bloat.
- **Performance optimization**: Review hasher selection, memory pre-allocation, zero-copy practices, and cache efficiency.
- **Safety & Error handling**: Ensure predictable error boundaries, avoid premature unwraps/panics, and properly guard unsafe blocks.


## Applying These Guidelines
Treat `must` as expected to always hold; `should` allows flexibility. Teams may apply the guidelines as appropriate to their project.
Understand each guideline's rationale before making exceptions; do not follow its letter when doing so would violate its purpose.
Before choosing rules, check the project's explicit requirements and conventions, whether the change targets a library or application and a public API, and its MSRV, runtime, and deployment targets. Apply only relevant rules; do not introduce unrelated dependency, allocator, or public API changes solely to satisfy a guideline.
For each task, use the quick index or routing table below, then navigate directly to the target rule's anchor to review its rationale and text.

## Quick Index by Task
Curated entrypoints for common cross-cutting tasks. Each rule link jumps directly to its anchor in the canonical part file. For exhaustive coverage, consult the domain routing table below.

| Task Focus | Curated Direct Guidelines |
| :--- | :--- |
| **Error Handling & Panics** | [`M-ERRORS-CANONICAL-STRUCTS`](parts/02-2-libs-ux.md#M-ERRORS-CANONICAL-STRUCTS), [`M-FROM-ERROR`](parts/02-2-libs-ux.md#M-FROM-ERROR), [`M-APP-ERROR`](parts/04-apps.md#M-APP-ERROR), [`M-PANIC-IS-STOP`](parts/06-correctness.md#M-PANIC-IS-STOP), [`M-PANIC-ON-BUG`](parts/06-correctness.md#M-PANIC-ON-BUG), [`M-PANIC-CONTINUATION`](parts/06-correctness.md#M-PANIC-CONTINUATION), [`M-PANIC-MESSAGE`](parts/06-correctness.md#M-PANIC-MESSAGE) |
| **Type Modeling & Public API** | [`M-PUBLIC-DEBUG`](parts/01-universal.md#M-PUBLIC-DEBUG), [`M-PUBLIC-DISPLAY`](parts/01-universal.md#M-PUBLIC-DISPLAY), [`M-SHORT-NAMES`](parts/01-universal.md#M-SHORT-NAMES), [`M-REGULAR-FN`](parts/01-universal.md#M-REGULAR-FN), [`M-DONT-LEAK-TYPES`](parts/02-1-libs-interop.md#M-DONT-LEAK-TYPES), [`M-FOREIGN-REEXPORTS`](parts/02-1-libs-interop.md#M-FOREIGN-REEXPORTS), [`M-IMPL-ASREF`](parts/02-1-libs-interop.md#M-IMPL-ASREF), [`M-SIMPLE-ABSTRACTIONS`](parts/02-2-libs-ux.md#M-SIMPLE-ABSTRACTIONS), [`M-AVOID-WRAPPERS`](parts/02-2-libs-ux.md#M-AVOID-WRAPPERS), [`M-DI-HIERARCHY`](parts/02-2-libs-ux.md#M-DI-HIERARCHY), [`M-SERVICES-CLONE`](parts/02-2-libs-ux.md#M-SERVICES-CLONE), [`M-STRONG-TYPES`](parts/02-3-libs-resilience.md#M-STRONG-TYPES), [`M-STRONG-TYPES-GUARD`](parts/02-3-libs-resilience.md#M-STRONG-TYPES-GUARD), [`M-SINGLE-ITEM-PATH`](parts/10-ai.md#M-SINGLE-ITEM-PATH), [`M-RUST-SHAPED`](parts/10-ai.md#M-RUST-SHAPED) |
| **Builder Design & Validation** | [`M-INIT-BUILDER`](parts/02-2-libs-ux.md#M-INIT-BUILDER), [`M-INIT-CASCADED`](parts/02-2-libs-ux.md#M-INIT-CASCADED), [`M-BUILD-RESULT`](parts/02-3-libs-resilience.md#M-BUILD-RESULT) |
| **Async & Concurrency** | [`M-TYPES-SEND`](parts/02-1-libs-interop.md#M-TYPES-SEND), [`M-IMPL-IO`](parts/02-1-libs-interop.md#M-IMPL-IO), [`M-ASYNC-FN`](parts/02-2-libs-ux.md#M-ASYNC-FN), [`M-YIELD-POINTS`](parts/07-performance.md#M-YIELD-POINTS), [`M-ASYNC-STACK-SIZE`](parts/07-performance.md#M-ASYNC-STACK-SIZE) |
| **Testing & Verification** | [`M-STATIC-VERIFICATION`](parts/01-universal.md#M-STATIC-VERIFICATION), [`M-LINT-OVERRIDE-EXPECT`](parts/01-universal.md#M-LINT-OVERRIDE-EXPECT), [`M-MOCKABLE-SYSCALLS`](parts/02-3-libs-resilience.md#M-MOCKABLE-SYSCALLS), [`M-TEST-UTIL`](parts/02-3-libs-resilience.md#M-TEST-UTIL), [`M-INTEGRATION-TESTS`](parts/02-3-libs-resilience.md#M-INTEGRATION-TESTS), [`M-TAUTOLOGICAL-TESTS`](parts/10-ai.md#M-TAUTOLOGICAL-TESTS), [`M-PROC-IMPL`](parts/03-macros.md#M-PROC-IMPL) |
| **Logging & Diagnostics** | [`M-LOG-STRUCTURED`](parts/01-universal.md#M-LOG-STRUCTURED), [`M-LOG-NOT-PRINT`](parts/02-3-libs-resilience.md#M-LOG-NOT-PRINT), [`M-LOG-OVERHEAD`](parts/07-performance.md#M-LOG-OVERHEAD) |
| **Performance & Memory** | [`M-MIMALLOC-APPS`](parts/04-apps.md#M-MIMALLOC-APPS), [`M-TARGET-CPU`](parts/04-apps.md#M-TARGET-CPU), [`M-HOTPATH`](parts/07-performance.md#M-HOTPATH), [`M-MEM-REUSE`](parts/07-performance.md#M-MEM-REUSE), [`M-AVOID-INDIRECTION`](parts/07-performance.md#M-AVOID-INDIRECTION), [`M-BOX-DST`](parts/07-performance.md#M-BOX-DST), [`M-SHRINK-TO-FIT`](parts/07-performance.md#M-SHRINK-TO-FIT), [`M-FAST-HASHER`](parts/07-performance.md#M-FAST-HASHER), [`M-INITIAL-CAPACITY`](parts/07-performance.md#M-INITIAL-CAPACITY) |

## Guidelines Routing Table (Parts Index)
Choose and inspect the relevant part file based on your current task:

| Part File | Domain | Rules | Key Guidelines (IDs) |
| :--- | :--- | :---: | :--- |
| [`01-universal.md`](parts/01-universal.md) | Universal Guidelines | 11 | `M-UPSTREAM-GUIDELINES`, `M-STATIC-VERIFICATION`, `M-LINT-OVERRIDE-EXPECT`, `M-PUBLIC-DEBUG`, `M-PUBLIC-DISPLAY`, `M-SMALLER-CRATES`, `M-WEASEL-WORDS`, `M-SHORT-NAMES`, `M-REGULAR-FN`, `M-DOCUMENTED-MAGIC`, `M-LOG-STRUCTURED` |
| [`02-1-libs-interop.md`](parts/02-1-libs-interop.md) | Libraries - Interoperability | 7 | `M-TYPES-SEND`, `M-ESCAPE-HATCHES`, `M-DONT-LEAK-TYPES`, `M-FOREIGN-REEXPORTS`, `M-IMPL-ASREF`, `M-IMPL-RANGEBOUNDS`, `M-IMPL-IO` |
| [`02-2-libs-ux.md`](parts/02-2-libs-ux.md) | Libraries - API UX | 14 | `M-SIMPLE-ABSTRACTIONS`, `M-AVOID-WRAPPERS`, `M-DI-HIERARCHY`, `M-ERRORS-CANONICAL-STRUCTS`, `M-FROM-ERROR`, `M-INIT-BUILDER`, `M-INIT-CASCADED`, `M-SERVICES-CLONE`, `M-ESSENTIAL-FN-INHERENT`, `M-BALANCED-MODULES`, `M-NO-PRELUDE`, `M-PARAMETER-CONSISTENCY`, `M-COLLECTION-TRAITS`, `M-ASYNC-FN` |
| [`02-3-libs-resilience.md`](parts/02-3-libs-resilience.md) | Libraries - Resilience & Robustness | 9 | `M-MOCKABLE-SYSCALLS`, `M-TEST-UTIL`, `M-INTEGRATION-TESTS`, `M-STRONG-TYPES`, `M-STRONG-TYPES-GUARD`, `M-BUILD-RESULT`, `M-NO-GLOB-REEXPORTS`, `M-AVOID-STATICS`, `M-LOG-NOT-PRINT` |
| [`02-4-libs-building.md`](parts/02-4-libs-building.md) | Libraries - Building & Cargo Features | 3 | `M-OOBE`, `M-SYS-CRATES`, `M-FEATURES-ADDITIVE` |
| [`03-macros.md`](parts/03-macros.md) | Macro Design & Safety | 7 | `M-MACRO-LAST-RESORT`, `M-EXAMPLE-OVER-PROC`, `M-MACROS-DONT-LIE`, `M-MACRO-MAIN-CRATE`, `M-MACRO-HELPERS`, `M-PROC-IMPL`, `M-PROC-IMPLIED-ITEMS` |
| [`04-apps.md`](parts/04-apps.md) | Application Binary Design | 3 | `M-MIMALLOC-APPS`, `M-APP-ERROR`, `M-TARGET-CPU` |
| [`05-ffi.md`](parts/05-ffi.md) | FFI & Native Interoperability | 3 | `M-ISOLATE-DLL-STATE`, `M-FFI-TRANSLATES`, `M-FFI-NAMING` |
| [`06-correctness.md`](parts/06-correctness.md) | Correctness & Bug Prevention | 7 | `M-UNSAFE`, `M-UNSOUND`, `M-UNSAFE-IMPLIES-UB`, `M-PANIC-IS-STOP`, `M-PANIC-ON-BUG`, `M-PANIC-CONTINUATION`, `M-PANIC-MESSAGE` |
| [`07-performance.md`](parts/07-performance.md) | Performance & Resource Optimization | 11 | `M-THROUGHPUT`, `M-HOTPATH`, `M-YIELD-POINTS`, `M-MEM-REUSE`, `M-LOG-OVERHEAD`, `M-AVOID-INDIRECTION`, `M-BOX-DST`, `M-SHRINK-TO-FIT`, `M-FAST-HASHER`, `M-INITIAL-CAPACITY`, `M-ASYNC-STACK-SIZE` |
| [`08-project.md`](parts/08-project.md) | Project Structure & CI | 5 | `M-CARGO-WORKSPACE`, `M-CRATES-IN-WORKSPACE`, `M-CRATES-FLAT-FOLDER`, `M-LATEST-EDITION`, `M-MSRV` |
| [`09-docs.md`](parts/09-docs.md) | Documentation Best Practices | 4 | `M-FIRST-DOC-SENTENCE`, `M-MODULE-DOCS`, `M-CANONICAL-DOCS`, `M-DOC-INLINE` |
| [`10-ai.md`](parts/10-ai.md) | Designing for AI Assistance | 5 | `M-DESIGN-FOR-AI`, `M-SINGLE-ITEM-PATH`, `M-NO-META-DESIGN-DOCUMENTATION`, `M-TAUTOLOGICAL-TESTS`, `M-RUST-SHAPED` |

## Best Practices for AI Agents Using This Skill
1. **Targeted Reading via Anchors**: Prefer reading only the relevant rules. Resolve each link relative to this skill directory. If your file-reading tool does not support fragment navigation, search the target file for the exact anchor (e.g. `<a id="M-STRONG-TYPES"></a>`), then read through the next rule anchor or end of file, including rationale, exceptions, and examples. If range reads are unavailable, reading the whole file is acceptable. Follow related rules when needed to understand applicability.
2. **Spirit Over Letter**: The guidelines exist to safeguard safety, efficiency, and clarity. Understand the rationale behind each guideline before applying or making exceptions.
3. **Rust-Shaped Solutions**: Do not directly transliterate C++/Java/C# OOP patterns into Rust. Follow Rust idioms (ownership, traits, exhaustive matching, explicit errors).

## Source Revision
- Repository: https://github.com/microsoft/rust-guidelines
- Incorporated revision: [`46e57284865473dedbf605f6b3e50666febd8802`](https://github.com/microsoft/rust-guidelines/commit/46e57284865473dedbf605f6b3e50666febd8802)
- Revision committed at: 2026-09-15T14:42:09+02:00
