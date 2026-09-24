> **[Example: Overlong summary sentence causing word wrapping/widows (Bad)]**
> - `DuplicateKeysError`: If you try to merge two Contexts together which have duplicate keys, this is the error you  
>   `get.` *(<- awkward single-word line wrap)*
> - `Fragment`: Contains a single layer of configuration data (from one source) which can be merged with  
>   data from other sources to yield a merged fragment to be deserialized into a concrete  
>   configuration type. *(<- spans 3 lines, hard to scan in summary table)*
> - `InternalContractViolationError`: An error that signals some internal API contract or logical condition was violated.
> - `MergedContext`
> - `Snapshot`: A snapshot of a config value T, allowing the value to be read. This type transparently takes  
>   care of resource management concerns required to expose the values efficiently.
> - `View`: A view over a configuration of type T, containing data for a specific context.
