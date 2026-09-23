> **[Benchmark Summary: Mutex vs RefCell with Base (Violin Plot)]**
> - **Infrequent to moderate atomic operations (>= 64 words interval)**: The cycle count difference between atomic/uncontended mutex operations (~16k cycles) and non-atomic (`RefCell`) operations is negligible.
> - **Extreme frequency (1–3 words interval)**: Tight loops acquiring atomic locks on every word cause significant overhead (350k–500k cycles).
> - **Conclusion**: Occasional uncontended atomic operations in otherwise thread-per-core async code incur no measurable performance penalty, while providing broad ecosystem compatibility (`Send` + `Sync`).
