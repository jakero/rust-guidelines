# Application Binary Design

> Pragmatic Rust Guidelines - Part 04
> Source category: `apps`

## Table of Contents

- **Use mimalloc for apps (M-MIMALLOC-APPS)**: significant performance at no cost.
- **Applications may use Anyhow or derivatives (M-APP-ERROR)**: simple application-level error handling.
- **Applications target highest viable target-cpu (M-TARGET-CPU)**: fleet performance.

---


<a id="M-MIMALLOC-APPS"></a>

## Use mimalloc for apps (M-MIMALLOC-APPS)

> **Rationale**: significant performance at no cost.

Applications should set [mimalloc](https://crates.io/crates/mimalloc) as their global allocator. This usually results in notable performance
increases along allocating hot paths; we have seen up to 25% benchmark improvements.

Changing the allocator only takes a few lines of code. Add mimalloc to your `Cargo.toml` like so:

```toml
[dependencies]
mimalloc = { version = "0.1" } # Or later version if available
```

Then use it from your `main.rs`:

```rust,ignore
use mimalloc::MiMalloc;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;
```

---


<a id="M-APP-ERROR"></a>

## Applications may use Anyhow or derivatives (M-APP-ERROR)

> **Rationale**: simple application-level error handling.

> Note, this guideline is primarily a relaxation and clarification of [M-ERRORS-CANONICAL-STRUCTS].

Applications, and crates in your own repository exclusively used from your application, may use [ohno::AppError](https://docs.rs/crate/ohno/latest#structs), [anyhow](https://github.com/dtolnay/anyhow),
[eyre](https://github.com/eyre-rs/eyre) or similar application-level error crates instead of implementing their own types.

For example, in your application crates you may just re-export and use eyre's common `Result` type, which should be able to automatically
handle all third party library errors, in particular the ones following
[M-ERRORS-CANONICAL-STRUCTS].

```rust,ignore
use ohno::AppError;

fn start_application() -> Result<(), AppError> {
    start_server()?;
    Ok(())
}
```

Once you selected your application error crate you should switch all application-level errors to that type, and you should not mix multiple
application-level error types.

Libraries (crates used by more than one crate) should always follow [M-ERRORS-CANONICAL-STRUCTS] instead.

[M-ERRORS-CANONICAL-STRUCTS]: ./02-2-libs-ux.md#M-ERRORS-CANONICAL-STRUCTS

---


<a id="M-TARGET-CPU"></a>

## Applications target highest viable target-cpu (M-TARGET-CPU)

> **Rationale**: fleet performance.

Server applications should compile against the highest `target-cpu` that the deployment environment is guaranteed to support, rather than defaulting to the generic baseline.

This can be achieved, for example, by setting inside `.cargo/config.toml`:

```toml
[target.x86_64-unknown-linux-gnu]
rustflags = ["-C", "target-cpu=x86-64-v3"]

[target.x86_64-pc-windows-msvc]
rustflags = ["-C", "target-cpu=x86-64-v3"]

# Add other platforms here based on needs ...
```

Note this guideline applies only to applications, as target settings are ignored for libraries.

---

