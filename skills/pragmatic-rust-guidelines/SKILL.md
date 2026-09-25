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
Read the [source overview](parts/00-1-overview.md) for the full design principles and applicability guidance. For each task, use the routing table to select relevant parts, then read their table of contents, rationale, and guideline text before applying a rule.

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
1. **Targeted Reading**: Do not load the entire guideline corpus at once. Look at the routing table above, locate the specific domain file (e.g., `parts/07-performance.md`), and inspect only that file.
2. **Spirit Over Letter**: The guidelines exist to safeguard safety, efficiency, and clarity. Understand the rationale behind each guideline before applying or making exceptions.
3. **Rust-Shaped Solutions**: Do not directly transliterate C++/Java/C# OOP patterns into Rust. Follow Rust idioms (ownership, traits, exhaustive matching, explicit errors).
