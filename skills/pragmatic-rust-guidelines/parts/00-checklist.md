
# Checklist

- **Universal**
  - [ ] Follow the upstream guidelines ([M-UPSTREAM-GUIDELINES])
  - [ ] Use static verification ([M-STATIC-VERIFICATION])
  - [ ] Lint overrides should use `#[expect]` ([M-LINT-OVERRIDE-EXPECT])
  - [ ] Public types are Debug ([M-PUBLIC-DEBUG])
  - [ ] Public types meant to be read are Display ([M-PUBLIC-DISPLAY])
  - [ ] If in doubt, split the crate ([M-SMALLER-CRATES])
  - [ ] Names are free of weasel words ([M-WEASEL-WORDS])
  - [ ] Names of items are short ([M-SHORT-NAMES])
  - [ ] Prefer regular over associated functions ([M-REGULAR-FN])
  - [ ] Magic values are documented ([M-DOCUMENTED-MAGIC])
  - [ ] Use structured logging with message templates ([M-LOG-STRUCTURED])
- **Library / Interoperability**
  - [ ] Types are Send ([M-TYPES-SEND])
  - [ ] Native escape hatches ([M-ESCAPE-HATCHES])
  - [ ] Don't leak external types ([M-DONT-LEAK-TYPES])
  - [ ] Items come from their original crate ([M-FOREIGN-REEXPORTS])
  - [ ] Accept `impl AsRef<>` where feasible ([M-IMPL-ASREF])
  - [ ] Accept `impl RangeBounds<>` where feasible ([M-IMPL-RANGEBOUNDS])
  - [ ] Accept `impl 'IO'` where feasible ('sans IO') ([M-IMPL-IO])
- **Library / UX**
  - [ ] Abstractions don't visibly nest ([M-SIMPLE-ABSTRACTIONS])
  - [ ] Avoid smart pointers and wrappers in APIs ([M-AVOID-WRAPPERS])
  - [ ] Prefer types over generics, generics over dyn traits ([M-DI-HIERARCHY])
  - [ ] Errors are canonical structs ([M-ERRORS-CANONICAL-STRUCTS])
  - [ ] Canonical error conversion uses `From`, not `map_err` ([M-FROM-ERROR])
  - [ ] Complex type construction has builders ([M-INIT-BUILDER])
  - [ ] Complex type initialization hierarchies are cascaded ([M-INIT-CASCADED])
  - [ ] Services are Clone ([M-SERVICES-CLONE])
  - [ ] Essential functionality should be inherent ([M-ESSENTIAL-FN-INHERENT])
  - [ ] Modules are balanced in size and scope ([M-BALANCED-MODULES])
  - [ ] Don't define preludes ([M-NO-PRELUDE])
  - [ ] Parameter ordering is consistent ([M-PARAMETER-CONSISTENCY])
  - [ ] Collections implement the appropriate iter traits ([M-COLLECTION-TRAITS])
  - [ ] Functions are `async` over returning a Future ([M-ASYNC-FN])
- **Library / Resilience**
  - [ ] I/O and system calls are mockable ([M-MOCKABLE-SYSCALLS])
  - [ ] Test utilities are feature gated ([M-TEST-UTIL])
  - [ ] Integration tests live under `tests/` ([M-INTEGRATION-TESTS])
  - [ ] Use the proper type family ([M-STRONG-TYPES])
  - [ ] Newtypes guard their invariants ([M-STRONG-TYPES-GUARD])
  - [ ] Builders validate in final `.build()` ([M-BUILD-RESULT])
  - [ ] Don't glob re-export items ([M-NO-GLOB-REEXPORTS])
  - [ ] Avoid statics ([M-AVOID-STATICS])
  - [ ] Production code uses telemetry, not println ([M-LOG-NOT-PRINT])
- **Library / Building**
  - [ ] Libraries work out of the box ([M-OOBE])
  - [ ] Native `-sys` crates compile without dependencies ([M-SYS-CRATES])
  - [ ] Features are additive ([M-FEATURES-ADDITIVE])
- **Macros**
  - [ ] Macros are a last resort ([M-MACRO-LAST-RESORT])
  - [ ] Prefer 'macros by example' over proc macros ([M-EXAMPLE-OVER-PROC])
  - [ ] Macros don't lie about signatures ([M-MACROS-DONT-LIE])
  - [ ] Macros assume main crate ([M-MACRO-MAIN-CRATE])
  - [ ] Third party items come from hidden `_private` module ([M-MACRO-HELPERS])
  - [ ] Proc macros should have separate impl crate incl. tests ([M-PROC-IMPL])
  - [ ] Proc macros don't produce implied or hidden items ([M-PROC-IMPLIED-ITEMS])
- **Applications**
  - [ ] Use mimalloc for apps ([M-MIMALLOC-APPS])
  - [ ] Applications may use Anyhow or derivatives ([M-APP-ERROR])
  - [ ] Applications target highest viable target-cpu ([M-TARGET-CPU])
- **FFI**
  - [ ] Isolate DLL state between FFI libraries ([M-ISOLATE-DLL-STATE])
  - [ ] Business logic belongs in core crates, FFI only translates ([M-FFI-TRANSLATES])
  - [ ] FFI crates follow established naming conventions ([M-FFI-NAMING])
- **Correctness**
  - [ ] Unsafe needs reason, should be avoided ([M-UNSAFE])
  - [ ] Unsafe implies undefined behavior ([M-UNSAFE-IMPLIES-UB])
  - [ ] All code must be sound ([M-UNSOUND])
  - [ ] Panic means 'stop the program' ([M-PANIC-IS-STOP])
  - [ ] Detected programming bugs are panics, not errors ([M-PANIC-ON-BUG])
  - [ ] Panic continuation is last resort ([M-PANIC-CONTINUATION])
  - [ ] Custom panics have a helpful message ([M-PANIC-MESSAGE])
- **Performance**
  - [ ] Optimize for throughput, avoid empty cycles ([M-THROUGHPUT])
  - [ ] Identify, profile, optimize the hot path early ([M-HOTPATH])
  - [ ] Long-running tasks should have yield points ([M-YIELD-POINTS])
  - [ ] Reuse allocations where possible ([M-MEM-REUSE])
  - [ ] Library telemetry does not tank performance ([M-LOG-OVERHEAD])
  - [ ] Nested type hierarchies should avoid needless indirection ([M-AVOID-INDIRECTION])
  - [ ] Use boxed slices and strings for immutable owned sequences ([M-BOX-DST])
  - [ ] Shrink collections to fit after building ([M-SHRINK-TO-FIT])
  - [ ] Use a fast hasher where possible ([M-FAST-HASHER])
  - [ ] Collections are created with sufficient initial capacity ([M-INITIAL-CAPACITY])
  - [ ] Hot `async` functions reduce stack size ([M-ASYNC-STACK-SIZE])
- **Project**
  - [ ] Common settings come from the workspace Cargo.toml ([M-CARGO-WORKSPACE])
  - [ ] The workspace lists and versions all crates ([M-CRATES-IN-WORKSPACE])
  - [ ] All crates are siblings in one folder ([M-CRATES-FLAT-FOLDER])
  - [ ] New crates target latest edition ([M-LATEST-EDITION])
  - [ ] MSRV is conservatively updated ([M-MSRV])
- **Documentation**
  - [ ] First sentence is one line; approx. 15 words ([M-FIRST-DOC-SENTENCE])
  - [ ] Has comprehensive module documentation ([M-MODULE-DOCS])
  - [ ] Documentation has canonical sections ([M-CANONICAL-DOCS])
  - [ ] Mark `pub use` items with `#[doc(inline)]` ([M-DOC-INLINE])
- **AI**
  - [ ] Design with AI use in mind ([M-DESIGN-FOR-AI])
  - [ ] Items are only visible through one path ([M-SINGLE-ITEM-PATH])
  - [ ] Avoid meta design documentation ([M-NO-META-DESIGN-DOCUMENTATION])
  - [ ] Tests do not assert ground truth ([M-TAUTOLOGICAL-TESTS])
  - [ ] Rust code solves Rust problems ([M-RUST-SHAPED])

<!-- Universal  -->
[M-UPSTREAM-GUIDELINES]: ./01-universal.md#M-UPSTREAM-GUIDELINES
[M-STATIC-VERIFICATION]: ./01-universal.md#M-STATIC-VERIFICATION
[M-LINT-OVERRIDE-EXPECT]: ./01-universal.md#M-LINT-OVERRIDE-EXPECT
[M-PUBLIC-DEBUG]: ./01-universal.md#M-PUBLIC-DEBUG
[M-PUBLIC-DISPLAY]: ./01-universal.md#M-PUBLIC-DISPLAY
[M-SMALLER-CRATES]: ./01-universal.md#M-SMALLER-CRATES
[M-WEASEL-WORDS]: ./01-universal.md#M-WEASEL-WORDS
[M-SHORT-NAMES]: ./01-universal.md#M-SHORT-NAMES
[M-REGULAR-FN]: ./01-universal.md#M-REGULAR-FN
[M-DOCUMENTED-MAGIC]: ./01-universal.md#M-DOCUMENTED-MAGIC
[M-LOG-STRUCTURED]: ./01-universal.md#M-LOG-STRUCTURED
[M-LOG-NOT-PRINT]: ./02.3-libs-resilience.md#M-LOG-NOT-PRINT

<!-- Libs -->
[M-TYPES-SEND]: ./02.1-libs-interop.md#M-TYPES-SEND
[M-DONT-LEAK-TYPES]: ./02.1-libs-interop.md#M-DONT-LEAK-TYPES
[M-FOREIGN-REEXPORTS]: ./02.1-libs-interop.md#M-FOREIGN-REEXPORTS
[M-ESCAPE-HATCHES]: ./02.1-libs-interop.md#M-ESCAPE-HATCHES
[M-STRONG-TYPES]: ./02.3-libs-resilience.md#M-STRONG-TYPES
[M-STRONG-TYPES-GUARD]: ./02.3-libs-resilience.md#M-STRONG-TYPES-GUARD
[M-NO-GLOB-REEXPORTS]: ./02.3-libs-resilience.md#M-NO-GLOB-REEXPORTS
[M-ESSENTIAL-FN-INHERENT]: ./02.2-libs-ux.md#M-ESSENTIAL-FN-INHERENT
[M-MOCKABLE-SYSCALLS]: ./02.3-libs-resilience.md#M-MOCKABLE-SYSCALLS
[M-SIMPLE-ABSTRACTIONS]: ./02.2-libs-ux.md#M-SIMPLE-ABSTRACTIONS
[M-AVOID-WRAPPERS]: ./02.2-libs-ux.md#M-AVOID-WRAPPERS
[M-DI-HIERARCHY]: ./02.2-libs-ux.md#M-DI-HIERARCHY
[M-ERRORS-CANONICAL-STRUCTS]: ./02.2-libs-ux.md#M-ERRORS-CANONICAL-STRUCTS
[M-FROM-ERROR]: ./02.2-libs-ux.md#M-FROM-ERROR
[M-INIT-BUILDER]: ./02.2-libs-ux.md#M-INIT-BUILDER
[M-BUILD-RESULT]: ./02.3-libs-resilience.md#M-BUILD-RESULT
[M-INIT-CASCADED]: ./02.2-libs-ux.md#M-INIT-CASCADED
[M-SERVICES-CLONE]: ./02.2-libs-ux.md#M-SERVICES-CLONE
[M-IMPL-ASREF]: ./02.1-libs-interop.md#M-IMPL-ASREF
[M-IMPL-RANGEBOUNDS]: ./02.1-libs-interop.md#M-IMPL-RANGEBOUNDS
[M-IMPL-IO]: ./02.1-libs-interop.md#M-IMPL-IO
[M-BALANCED-MODULES]: ./02.2-libs-ux.md#M-BALANCED-MODULES
[M-NO-PRELUDE]: ./02.2-libs-ux.md#M-NO-PRELUDE
[M-PARAMETER-CONSISTENCY]: ./02.2-libs-ux.md#M-PARAMETER-CONSISTENCY
[M-COLLECTION-TRAITS]: ./02.2-libs-ux.md#M-COLLECTION-TRAITS
[M-ASYNC-FN]: ./02.2-libs-ux.md#M-ASYNC-FN
[M-TEST-UTIL]: ./02.3-libs-resilience.md#M-TEST-UTIL
[M-INTEGRATION-TESTS]: ./02.3-libs-resilience.md#M-INTEGRATION-TESTS
[M-AVOID-STATICS]: ./02.3-libs-resilience.md#M-AVOID-STATICS
[M-OOBE]: ./02.4-libs-building.md#M-OOBE
[M-SYS-CRATES]: ./02.4-libs-building.md#M-SYS-CRATES
[M-FEATURES-ADDITIVE]: ./02.4-libs-building.md#M-FEATURES-ADDITIVE

<!-- Apps -->
[M-APP-ERROR]: ./04-apps.md#M-APP-ERROR
[M-MIMALLOC-APPS]: ./04-apps.md#M-MIMALLOC-APPS
[M-TARGET-CPU]: ./04-apps.md#M-TARGET-CPU

<!-- FFI -->
[M-ISOLATE-DLL-STATE]: ./05-ffi.md#M-ISOLATE-DLL-STATE
[M-FFI-TRANSLATES]: ./05-ffi.md#M-FFI-TRANSLATES
[M-FFI-NAMING]: ./05-ffi.md#M-FFI-NAMING

<!-- Correctness -->
[M-UNSAFE]: ./06-correctness.md#M-UNSAFE
[M-UNSAFE-IMPLIES-UB]: ./06-correctness.md#M-UNSAFE-IMPLIES-UB
[M-UNSOUND]: ./06-correctness.md#M-UNSOUND
[M-PANIC-IS-STOP]: ./06-correctness.md#M-PANIC-IS-STOP
[M-PANIC-ON-BUG]: ./06-correctness.md#M-PANIC-ON-BUG
[M-PANIC-CONTINUATION]: ./06-correctness.md#M-PANIC-CONTINUATION
[M-PANIC-MESSAGE]: ./06-correctness.md#M-PANIC-MESSAGE

<!-- Performance -->
[M-HOTPATH]: ./07-performance.md#M-HOTPATH
[M-THROUGHPUT]: ./07-performance.md#M-THROUGHPUT
[M-YIELD-POINTS]: ./07-performance.md#M-YIELD-POINTS
[M-MEM-REUSE]: ./07-performance.md#M-MEM-REUSE
[M-LOG-OVERHEAD]: ./07-performance.md#M-LOG-OVERHEAD
[M-AVOID-INDIRECTION]: ./07-performance.md#M-AVOID-INDIRECTION
[M-BOX-DST]: ./07-performance.md#M-BOX-DST
[M-SHRINK-TO-FIT]: ./07-performance.md#M-SHRINK-TO-FIT
[M-FAST-HASHER]: ./07-performance.md#M-FAST-HASHER
[M-INITIAL-CAPACITY]: ./07-performance.md#M-INITIAL-CAPACITY
[M-ASYNC-STACK-SIZE]: ./07-performance.md#M-ASYNC-STACK-SIZE

<!-- Project -->
[M-CARGO-WORKSPACE]: ./08-project.md#M-CARGO-WORKSPACE
[M-CRATES-IN-WORKSPACE]: ./08-project.md#M-CRATES-IN-WORKSPACE
[M-CRATES-FLAT-FOLDER]: ./08-project.md#M-CRATES-FLAT-FOLDER
[M-LATEST-EDITION]: ./08-project.md#M-LATEST-EDITION
[M-MSRV]: ./08-project.md#M-MSRV

<!-- Docs -->
[M-FIRST-DOC-SENTENCE]: ./09-docs.md#M-FIRST-DOC-SENTENCE
[M-MODULE-DOCS]: ./09-docs.md#M-MODULE-DOCS
[M-CANONICAL-DOCS]: ./09-docs.md#M-CANONICAL-DOCS
[M-DOC-INLINE]: ./09-docs.md#M-DOC-INLINE

<!-- Macros -->
[M-MACRO-LAST-RESORT]: ./03-macros.md#M-MACRO-LAST-RESORT
[M-EXAMPLE-OVER-PROC]: ./03-macros.md#M-EXAMPLE-OVER-PROC
[M-MACROS-DONT-LIE]: ./03-macros.md#M-MACROS-DONT-LIE
[M-MACRO-MAIN-CRATE]: ./03-macros.md#M-MACRO-MAIN-CRATE
[M-MACRO-HELPERS]: ./03-macros.md#M-MACRO-HELPERS
[M-PROC-IMPL]: ./03-macros.md#M-PROC-IMPL
[M-PROC-IMPLIED-ITEMS]: ./03-macros.md#M-PROC-IMPLIED-ITEMS

<!-- AI -->
[M-DESIGN-FOR-AI]: ./10-ai.md#M-DESIGN-FOR-AI
[M-SINGLE-ITEM-PATH]: ./10-ai.md#M-SINGLE-ITEM-PATH
[M-NO-META-DESIGN-DOCUMENTATION]: ./10-ai.md#M-NO-META-DESIGN-DOCUMENTATION
[M-TAUTOLOGICAL-TESTS]: ./10-ai.md#M-TAUTOLOGICAL-TESTS
[M-RUST-SHAPED]: ./10-ai.md#M-RUST-SHAPED
