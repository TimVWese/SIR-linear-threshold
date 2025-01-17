# Experiment name
name = "sf"
title = "Scale Free"

# Experiment selection
α_Θ_exps = true
β_crit_exps = false
ρ_β_exps = false
ρ_ω_exps = false
ρ_t_exps = true

# Default paramameters
n = 64
n_small = 20
β = 0.2
μ = 0.15
ν = 0.0
α = 0.5
Θ = 0.45

Tₑ = 500
Nb_networks = 5
Nb_outers = 8
Nb_trajectories = 25

step = 0.025
β_range = 0:0.0125:0.4
ω_range = 0:0.025:1

nb_I = 4
prop_A = 0.5

multiplex = false
network_epi() = SF_configuration_model(n^2, 2.72; min_d=3)
network_epi_small() = SF_configuration_model(n_small^2, 2.72; min_d=3)

x₀_gen!(x) = init!(x; nb_I=nb_I, prop_A=prop_A)

early_termination = false

prec_occ = 2
prec_dim = "y"

# α-Θ phase plane plots
α_Θ_params = (
    extended = true,
    N = n^2,

    xs = 0:step:1,
    ys = 0:step:1,

    dynamics = dynamics,

    x₀_gen! = x₀_gen!,

    β = β,
    p_gen = (α, Θ) -> (β = β, μ = μ, ν = ν, Θ = Θ, α = α),

    Tₑ = Tₑ,
    Nb_networks = Nb_networks,
    Nb = Nb_trajectories,

    min_T = 4,
    early_termination = early_termination,

    xlabel = "α",
    ylabel = "Θ",

    prec=Dict("bs" => (2, prec_dim, prec_occ)),

    max_T_hm_lim = Tₑ/5,
    max_A_hm_lim = 1.0,
    max_I_hm_lim = 0.25,
)

# βᶜ value calculation

β_crit_params = (
    N = n_small^2,

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
    N = n^2,

    βs = β_range,
    xs = 0:0.25:1,

    dynamics = dynamics,

    x₀_gen! = x₀_gen!,
    p_gen = (β, α) -> (β = β, μ = μ, ν = ν, Θ = Θ, α = α),

    Tₑ = Tₑ,
    Nb_networks = Nb_networks,
    Nb = Nb_trajectories,

    early_termination = early_termination,

    xlabel = "\$\\alpha\$",
)

ρ_ω_params = (
    N = n^2,

    ωs = ω_range,
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

# Evolution of I and A in time

ρ_t_params = (
    N = n^2,

    xs = 0:0.25:1,

    dynamics = dynamics,

    x₀_gen! = x₀_gen!,
    p_gen = (α) -> (β = β, μ = μ, ν = ν, Θ = Θ, α = α),

    Tₑ = Tₑ,
    Nb_networks = Nb_networks,
    Nb = Nb_trajectories,

    early_termination = early_termination,

    xlabel = "\$\\alpha\$",
)
