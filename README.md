# SIR - Linear Threshold epidemics

Companion code to [Epidemic risk perception and social interactions lead to awareness cascades on multiplex networks](https://arxiv.org/abs/2404.16466).

## Dependencies

Dependencies are in `Project.toml`.

[`General`](https://github.com/TimVWese/General.jl) and [`SIRLT`](https://github.com/TimVWese/SIRLT.jl) are not part of the Julia general registry. To install them, run

```julia
] dev https://github.com/TimVWese/General.jl https://github.com/TimVWese/SIRLT.jl
```

To install the others, run

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## Usage
Adjust the desired parameters in `setup.jl` than initialize with

```bash
julia init.jl
```

Run with

```bash
julia -t $n_threads run.jl $network_i
```

where `$n_threads` is the number of threads to use and `$network_i` is the index of the network to evaluate.
When all networks are evaluated, run

```bash
julia finalise.jl
```

to collect the results.

## Archived results
In the folder `archived_results` the results presented in the paper can be found.
