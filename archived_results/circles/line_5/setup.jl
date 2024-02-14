# Experiment name
name = "line_5"
title = "Circle 5"

# Experiment selcetion
α_Θ_exps = true
β_crit_exps = true
ρ_β_exps = true
ρ_t_exps = true
mmca_exps = true

# Default paramameters
n = 100
n_small = 100
β = 0.2
μ = 0.15
ν = 0.0
α = 0.5
Θ = 0.5

Tₑ = 500
Nb_networks = 5
Nb_outers = 8
Nb_trajectories = 25

step = 0.025
β_range = 0:0.0125:0.4

nb_I = 1
prop_A = 0.

multiplex = true
network_epi() = nothing
network_opi() = nothing
network_epi_small() = nothing
network_opi_small() = nothing

dynamics(epi, opi) = LuMV_bi(epi, opi; inf_A=true)
mmca_dynamics(epi, opi) = mmca.sir(epi, opi; inf_A=true)

dynamics(exp) = dynamics(read_from_mtx("graph_data/epi_$(exp).mtx"), read_from_mtx("graph_data/opi_$(exp).mtx"))
small_dynamics(exp) = dynamics(read_from_mtx("graph_data/epi_$(exp).mtx"), read_from_mtx("graph_data/opi_$(exp).mtx"))
mmca_dynamics(exp) = mmca_dynamics(read_from_mtx("graph_data/epi_$(exp).mtx"), read_from_mtx("graph_data/opi_$(exp).mtx"))

x₀_gen!(x) = init!(x; nb_I=nb_I, prop_A=prop_A)

early_termination = true

prec_occ = 2
prec_dim = "y"

# α-Θ phase plane plots
α_Θ_params = (
    extended = true,
    N = n,

    xs = 0:step:1,
    ys = 0:step:1,

    dynamics = dynamics,

    x₀_gen! = x₀_gen!,

    β = β,
    p_gen = (α, Θ) -> (β = β, μ = μ, ν = ν, Θ = Θ, α = α),

    Tₑ = Tₑ,
    Nb_networks = Nb_networks,
    Nb = Nb_trajectories,

    early_termination=early_termination,

    xlabel = "α",
    ylabel = "Θ",

    prec=Dict("bs" => (2, prec_dim, prec_occ)),

    max_T_hm_lim = Tₑ/5,
    max_A_hm_lim = 1.0,
    max_I_hm_lim = 0.25,
)

# βᶜ value calculation

β_crit_params = (
    N = n_small,

    xs = 0:step:1,
    ys = 0:step:1,
    ρs = [0.1, 0.9],

    dynamics = small_dynamics,

    x₀_gen! =  x₀_gen!,

    p_gen = (α, Θ) -> (β = β, μ = μ, ν = ν, Θ = Θ, α = α),

    Tₑ = 1000,
    Nb_networks = Nb_networks,
    Nb_o = Nb_outers,
    Nb_i = Nb_trajectories,

    xlabel = "α",
    ylabel = "Θ",

    prec=Dict(),
)

# Proprtion of A and R depending on β

ρ_β_params = (
    N = n,

    βs = β_range,
    xs = 0:0.25:1,

    dynamics = dynamics,

    x₀_gen! = x₀_gen!,
    p_gen = (β, α) -> (β = β, μ = μ, ν = ν, Θ = Θ, α = α),

    Tₑ = Tₑ,
    Nb_networks = Nb_networks,
    Nb = Nb_trajectories,

    early_termination=early_termination,

    xlabel = "\$\\alpha\$",
)

# Evolution of I and A in time

ρ_t_params = (
    N = n,

    xs = 0:0.25:1,

    dynamics = dynamics,

    x₀_gen! = x₀_gen!,
    p_gen = (α) -> (β = β, μ = μ, ν = ν, Θ = Θ, α = α),

    Tₑ = Tₑ,
    Nb_networks = Nb_networks,
    Nb = Nb_trajectories,

    early_termination=early_termination,

    xlabel = "\$\\alpha\$",
)

# MMCA version of proportion of A and R depending on βᶜ

mmca_params = (
    N = n,

    βs = ρ_β_params.βs, # best not to touch
    xs = ρ_β_params.xs, # best not to touch

    dynamics = mmca_dynamics,

    x₀_gen! = (x, ws) -> mmca.init!(x, ws; nb_I=nb_I, prop_A=prop_A),
    p_gen = (β, α) -> (β = β, μ = μ, Θ = Θ, α = α),

    Tₑ = Tₑ,
    Nb_networks = Nb_networks,
    Nb = Nb_trajectories,
)