# Project Structure & CI

> Pragmatic Rust Guidelines - Part 08
> Source category: `project`

## Table of Contents

- **Common settings come from the workspace Cargo.toml (M-CARGO-WORKSPACE)**: consistent, maintainable project configuration.
- **The workspace lists and versions all crates (M-CRATES-IN-WORKSPACE)**: simple inter-crate dependencies and debugging.
- **All crates are siblings in one folder (M-CRATES-FLAT-FOLDER)**: simple project navigation and a standard Rust layout.
- **New crates target latest edition (M-LATEST-EDITION)**: access to the latest Rust features.
- **MSRV is conservatively updated (M-MSRV)**: modern features with stability for users.

---


<a id="M-CARGO-WORKSPACE"></a>

## Common settings come from the workspace Cargo.toml (M-CARGO-WORKSPACE)

> **Rationale**: consistent, maintainable project configuration.

Any repo with two or more crates that somehow belong together should unify these crates with a workspace `Cargo.toml`. Members then inherit shared metadata and dependency versions from the workspace root via `[workspace.dependencies]`, `[workspace.lints]`, ... rather than duplicating these values in each crate.

Where a dependency is crate-specific, it should still be defined in the workspace. Workspace definitions should generally not enable dependency features (except basic ones such as `["std"]`), and should instead use `default-features = false`.

---


<a id="M-CRATES-IN-WORKSPACE"></a>

## The workspace lists and versions all crates (M-CRATES-IN-WORKSPACE)

> **Rationale**: simple inter-crate dependencies and debugging.

Every crate produced by the project should be listed as a workspace member, and its version should be declared in `[workspace.dependencies]` so that intra-workspace dependencies resolve to a single canonical version.

```toml
# Bad, crate links its sibling directly
[dependencies]
sibling.path = "../sibling"

# Good, going through workspace
[dependencies]
sibling.workspace = true

[workspace.dependencies]
sibling = { path = "crates/sibling", version = "0.5.2" }
```

---


<a id="M-CRATES-FLAT-FOLDER"></a>

## All crates are siblings in one folder (M-CRATES-FLAT-FOLDER)

> **Rationale**: simple project navigation and a standard Rust layout.

A repository should contain a single workspace `Cargo.toml`, and all Rust crates should be subordinate to it. All crates should then live in a single, direct subdirectory (e.g., `crates/`) below the workspace (for up to 1-2 dozen of crates), beyond that some folder hierarchy should be used (e.g., `common/`, `server/`, `client/`) to organize siblings.

```bash
# Ideal for most workspaces
Cargo.toml
crates/
  foo/Cargo.toml 
  foo_core/Cargo.toml 
  foo_proc/Cargo.toml 
  foo_tests/Cargo.toml 
  bar/Cargo.toml
  baz/Cargo.toml

# Ok for large workspaces
Cargo.toml
crates/
  server/
    main/Cargo.toml 
    routes/Cargo.toml 
  client/
    foo/Cargo.toml
    bar/Cargo.toml
  common/
    error/Cargo.toml
```

Placing crates inside other crates (at or below their `Cargo.toml`), or even inside their `src/` folder is never acceptable. If a crate relationship should be expressed, this is done via common prefixes instead (e.g., `foo`, `foo_util`, `foo_build`).

```bash
# Never acceptable, crates inside `src/` folder
Cargo.toml
crates/
  foo/Cargo.toml 
    src/lib.rs
       deps/bar/Cargo.toml 
```

Rare exceptions to this rule can occur if your crate is in the business of processing workspaces and has a collection of UI tests or similar it relies on; but even then these are usually dummy crates in nature.

---


<a id="M-LATEST-EDITION"></a>

## New crates target latest edition (M-LATEST-EDITION)

> **Rationale**: access to the latest Rust features.

When creating a new crate or workspace, set `edition` to the latest stable edition (at least `2024` at the time of writing); the `resolver` field is generally not needed.

Using an older edition generally has no upsides for new projects, but forces you to write 'old Rust' that is less idiomatic and has worse UX edge cases. Notably, using an older edition does _not_ grant any compatibility benefits with the rest of the ecosystem. An application based on `2015` can use libraries written for `2024` just fine.

---


<a id="M-MSRV"></a>

## MSRV is conservatively updated (M-MSRV)

> **Rationale**: modern features with stability for users.

A Minimum Supported Rust Version (MSRV) should be set when libraries are first created. It can be updated as new Rust features are needed, but should be kept a few versions behind the most recent compiler release.

The ecosystem expectation is that projects are compiled with a _reasonably modern_ Rust compiler.

Bumping MSRV therefore does not require a major release, but can be handled through a minor update (e.g., `1.3` to `1.4`). In fact, any project depending on 3rd party crates is already inherently bound to this contract; forcing a major version bump will not confer any benefits, but could possibly bifurcate downstream dependencies.

---

