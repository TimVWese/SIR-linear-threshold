# SIR - Linear Threshold epidemics

Companion code to ...

## Dependencies

Dependencies are in `Project.toml`.

`General` and `SIRLT` are not part of the Julia general registry. To install them, run

```julia
] dev https://github.com/TimVWese/General.jl https://github.com/TimVWese/SIRLT.jl
```

To install the others, run

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```
