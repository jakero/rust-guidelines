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

## Guidelines Routing Table (Parts Index)
Choose and inspect the relevant part file based on your current task:

| Part File | Domain | Rules | Key Guidelines (IDs) |
| :--- | :--- | :---: | :--- |
| [`01-universal.md`](parts/01-universal.md) | Universal Guidelines | 11 | `M-DOCUMENTED-MAGIC`, `M-LINT-OVERRIDE-EXPECT`, `M-LOG-STRUCTURED`, `M-PUBLIC-DEBUG`, `M-PUBLIC-DISPLAY`, `M-REGULAR-FN`, `M-SHORT-NAMES`, `M-SMALLER-CRATES`, `M-STATIC-VERIFICATION`, `M-UPSTREAM-GUIDELINES`, `M-WEASEL-WORDS` |
| [`02-libs-interop.md`](parts/02-libs-interop.md) | Libraries - Interoperability | 7 | `M-DONT-LEAK-TYPES`, `M-ESCAPE-HATCHES`, `M-FOREIGN-REEXPORTS`, `M-IMPL-ASREF`, `M-IMPL-IO`, `M-IMPL-RANGEBOUNDS`, `M-TYPES-SEND` |
| [`03-libs-ux.md`](parts/03-libs-ux.md) | Libraries - API UX | 14 | `M-ASYNC-FN`, `M-AVOID-WRAPPERS`, `M-BALANCED-MODULES`, `M-COLLECTION-TRAITS`, `M-DI-HIERARCHY`, `M-ERRORS-CANONICAL-STRUCTS`, `M-ESSENTIAL-FN-INHERENT`, `M-FROM-ERROR`, `M-INIT-BUILDER`, `M-INIT-CASCADED`, `M-NO-PRELUDE`, `M-PARAMETER-CONSISTENCY`, `M-SERVICES-CLONE`, `M-SIMPLE-ABSTRACTIONS` |
| [`04-libs-resilience.md`](parts/04-libs-resilience.md) | Libraries - Resilience & Robustness | 9 | `M-AVOID-STATICS`, `M-BUILD-RESULT`, `M-INTEGRATION-TESTS`, `M-LOG-NOT-PRINT`, `M-MOCKABLE-SYSCALLS`, `M-NO-GLOB-REEXPORTS`, `M-STRONG-TYPES-GUARD`, `M-STRONG-TYPES`, `M-TEST-UTIL` |
| [`05-libs-building.md`](parts/05-libs-building.md) | Libraries - Building & Cargo Features | 3 | `M-FEATURES-ADDITIVE`, `M-OOBE`, `M-SYS-CRATES` |
| [`06-correctness.md`](parts/06-correctness.md) | Correctness & Bug Prevention | 7 | `M-PANIC-CONTINUATION`, `M-PANIC-IS-STOP`, `M-PANIC-MESSAGE`, `M-PANIC-ON-BUG`, `M-UNSAFE-IMPLIES-UB`, `M-UNSAFE`, `M-UNSOUND` |
| [`07-performance.md`](parts/07-performance.md) | Performance & Resource Optimization | 11 | `M-ASYNC-STACK-SIZE`, `M-AVOID-INDIRECTION`, `M-BOX-DST`, `M-FAST-HASHER`, `M-HOTPATH`, `M-INITIAL-CAPACITY`, `M-LOG-OVERHEAD`, `M-MEM-REUSE`, `M-SHRINK-TO-FIT`, `M-THROUGHPUT`, `M-YIELD-POINTS` |
| [`08-apps.md`](parts/08-apps.md) | Application Binary Design | 3 | `M-APP-ERROR`, `M-MIMALLOC-APPS`, `M-TARGET-CPU` |
| [`09-ffi.md`](parts/09-ffi.md) | FFI & Native Interoperability | 3 | `M-FFI-NAMING`, `M-FFI-TRANSLATES`, `M-ISOLATE-DLL-STATE` |
| [`10-macros.md`](parts/10-macros.md) | Macro Design & Safety | 7 | `M-EXAMPLE-OVER-PROC`, `M-MACRO-HELPERS`, `M-MACRO-LAST-RESORT`, `M-MACRO-MAIN-CRATE`, `M-MACROS-DONT-LIE`, `M-PROC-IMPL`, `M-PROC-IMPLIED-ITEMS` |
| [`11-project.md`](parts/11-project.md) | Project Structure & CI | 5 | `M-CARGO-WORKSPACE`, `M-CRATES-FLAT-FOLDER`, `M-CRATES-IN-WORKSPACE`, `M-LATEST-EDITION`, `M-MSRV` |
| [`12-docs.md`](parts/12-docs.md) | Documentation Best Practices | 4 | `M-CANONICAL-DOCS`, `M-DOC-INLINE`, `M-FIRST-DOC-SENTENCE`, `M-MODULE-DOCS` |
| [`13-ai.md`](parts/13-ai.md) | Designing for AI Assistance | 5 | `M-DESIGN-FOR-AI`, `M-NO-META-DESIGN-DOCUMENTATION`, `M-RUST-SHAPED`, `M-SINGLE-ITEM-PATH`, `M-TAUTOLOGICAL-TESTS` |

## Best Practices for AI Agents Using This Skill
1. **Targeted Reading**: Do not load the entire guideline corpus at once. Look at the routing table above, locate the specific domain file (e.g., `parts/07-performance.md`), and inspect only that file.
2. **Spirit Over Letter**: The guidelines exist to safeguard safety, efficiency, and clarity. Understand the rationale behind each guideline before applying or making exceptions.
3. **Rust-Shaped Solutions**: Do not directly transliterate C++/Java/C# OOP patterns into Rust. Follow Rust idioms (ownership, traits, exhaustive matching, explicit errors).
