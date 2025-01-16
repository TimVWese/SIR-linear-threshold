using SIRLT
using General
using NetworkDynamics, Graphs
using DifferentialEquations: solve, DiscreteProblem, FunctionMap
using DelimitedFiles

function α_Θ(params, exp_nb)
    N = params.N
    Rs = zeros(length(params.xs), length(params.ys))
    As = zeros(length(params.xs), length(params.ys))
    Ts = zeros(length(params.xs), length(params.ys))
    if params.extended
        βs = zeros(length(params.xs), length(params.ys))
        max_Is = zeros(length(params.xs), length(params.ys))
        T_mIs = zeros(length(params.xs), length(params.ys))
        max_As = zeros(length(params.xs), length(params.ys))
        T_mAs = zeros(length(params.xs), length(params.ys))
    end

    network_epi = read_from_mtx("graph_data/epi_$exp_nb.mtx")
    avgₛs = [zeros(4) for i in 1:Threads.nthreads()]
    avgₒs = [zeros(2) for i in 1:Threads.nthreads()]
    x₀s = [zeros(2 * N) for i in 1:Threads.nthreads()]
    nds = [params.dynamics(exp_nb) for i in 1:Threads.nthreads()]

    for (x_idx, x) in enumerate(params.xs)
        Threads.@threads for y_idx in eachindex(params.ys)
            y = params.ys[y_idx]
            tid = Threads.threadid()
            avgₛ = avgₛs[tid]
            avgₒ = avgₒs[tid]
            x₀ = x₀s[tid]

            p = params.p_gen(x, y)
            if params.extended
                min_T = haskey(params, :min_T) ? params.min_T : 1
                T, βeq, max_I, T_mI, max_A, T_mA = solve_iter_final!(avgₛ, avgₒ, x₀, nds[tid], params.x₀_gen!, p, params.Tₑ, params.Nb, network_epi; early_termination=params.early_termination, min_T=min_T)
            else
                T = solve_iter_final!(avgₛ, avgₒ, x₀, nds[tid], params.x₀_gen!, p, params.Tₑ, params.Nb; early_termination=params.early_termination)
            end
            Rs[x_idx, y_idx] = avgₛ[3]
            As[x_idx, y_idx] = avgₒ[2]
            Ts[x_idx, y_idx] = T
            if params.extended
                βs[x_idx, y_idx] = βeq / p.β
                max_Is[x_idx, y_idx] = max_I
                T_mIs[x_idx, y_idx] = T_mI
                max_As[x_idx, y_idx] = max_A
                T_mAs[x_idx, y_idx] = T_mA
            end
        end
    end

    writedlm("heatmaps/data/Rs_$(exp_nb).dat", Rs)
    writedlm("heatmaps/data/As_$(exp_nb).dat", As)
    writedlm("heatmaps/data/Ts_$(exp_nb).dat", Ts)

    if params.extended
        writedlm("heatmaps/data/bs_$(exp_nb).dat", βs)
        writedlm("heatmaps/data/max_Is_$(exp_nb).dat", max_Is)
        writedlm("heatmaps/data/T_mIs_$(exp_nb).dat", T_mIs)
        writedlm("heatmaps/data/max_As_$(exp_nb).dat", max_As)
        writedlm("heatmaps/data/T_mAs_$(exp_nb).dat", T_mAs)
    end
end

function β_crit(params, exp_nb)
    N = params.N
    nb_ρ = length(params.ρs)
    x₀s = [zeros(2N) for i in 1:Threads.nthreads()]
    nds = [params.dynamics(exp_nb) for i in 1:Threads.nthreads()]

    for (ρ_idx, ρ) in enumerate(params.ρs)
        βs = Array{Float64}(undef, (length(params.xs), length(params.ys)))
        for (x_idx, x) in enumerate(params.xs)
            Threads.@threads for y_idx in eachindex(params.ys)
                y = params.ys[y_idx]
                p = params.p_gen(x, y)

                tid = Threads.threadid()
                x₀ = x₀s[tid]
                ρ = params.ρs[ρ_idx]
                Nb_succ = 0
                for _ in 1:params.Nb_o
                    try
                        βs[x_idx, y_idx] += β_critical(x₀, nds[tid], params.x₀_gen!, p; Nb=params.Nb_i, prop_I=ρ)
                        Nb_succ += 1
                    catch e
                        if !(e isa ArgumentError)
                            rethrow(e)
                        end
                    end
                end

                if Nb_succ > 0
                    βs[x_idx, y_idx] /= Nb_succ
                end
            end
        end
        id = string(ρ)[3:end]
        writedlm("heatmaps/data/bc" * id * "_$(exp_nb).dat", βs)
    end
end

function ρ_β(params, exp_nb)
    N = params.N

    Rs = zeros(length(params.xs), length(params.βs))
    As = zeros(length(params.xs), length(params.βs))

    avgₛs = [zeros(4) for i in 1:Threads.nthreads()]
    avgₒs = [zeros(2) for i in 1:Threads.nthreads()]
    x₀s = [zeros(2N) for i in 1:Threads.nthreads()]
    nds = [params.dynamics(exp_nb) for i in 1:Threads.nthreads()]

    for (x_idx, x) in enumerate(params.xs)
        Threads.@threads for β_idx in eachindex(params.βs)
            tid = Threads.threadid()
            avgₛ = avgₛs[tid]
            avgₒ = avgₒs[tid]
            x₀ = x₀s[tid]

            β = params.βs[β_idx]
            p = params.p_gen(β, x)
            solve_iter_final!(avgₛ, avgₒ, x₀, nds[tid], params.x₀_gen!, p, params.Tₑ, params.Nb; early_termination=params.early_termination)
            Rs[x_idx, β_idx] = avgₛ[3]
            As[x_idx, β_idx] = avgₒ[2]
        end
    end

    writedlm("ldata/Rs_$(exp_nb).dat", hcat(params.βs, Rs'))
    writedlm("ldata/As_$(exp_nb).dat", hcat(params.βs, As'))
end

function ρ_t(params, exp_nb)
    N = params.N

    Is = zeros(params.Tₑ, length(params.xs))
    As = zeros(params.Tₑ, length(params.xs))

    x₀s = [zeros(2N) for i in 1:Threads.nthreads()]
    nds = [params.dynamics(exp_nb) for i in 1:Threads.nthreads()]

    Threads.@threads for x_idx in eachindex(params.xs)
        tid = Threads.threadid()
        x₀ = x₀s[tid]
        x = params.xs[x_idx]

        p = params.p_gen(x)
        avgₛ, avgₒ = solve_iter_full(x₀, nds[tid], params.x₀_gen!, p, params.Tₑ, params.Nb; early_termination=params.early_termination)

        Is[:, x_idx] .= avgₛ[:, 2]
        As[:, x_idx] .= avgₒ[:, 2]
    end

    writedlm("tdata/Rs_$(exp_nb).dat", hcat(1:params.Tₑ, Is))
    writedlm("tdata/As_$(exp_nb).dat", hcat(1:params.Tₑ, As))
end

@assert length(ARGS) == 2 "Usage: julia run.jl <experiment_name> <network_number>"
try
    arg_name = ARGS[1][end] == '/' ? ARGS[1][1:end-1] : ARGS[1]
    include(arg_name * "/setup.jl")
    cd(arg_name)
catch
    @assert false "Mistake in experiment definition"
end

exp_nb = parse(Int64, ARGS[2])

function git_dir(package)
    path = split(pathof(package), "/")
    fi = findlast(x -> x == "src", path)
    fi = isnothing(fi) ? length(path)-1 : fi-1
    return "/"*joinpath(path[1:fi]..., ".git")
end

const General_dir = git_dir(General)
const SIRLT_dir = git_dir(SIRLT)
git_head(gitdir) = strip(read(`git --git-dir $gitdir rev-parse HEAD`, String))
git_status(gitdir) = begin
    workdir = gitdir[1:end-5]
    strip(read(`git --git-dir $gitdir --work-tree=$workdir status`, String))
end

const git_heads = (
    strip(read(`git rev-parse HEAD`, String)), # project
    git_head(General_dir), # General
    git_head(SIRLT_dir), # SIRLT
    git_status(SIRLT_dir), # SIRLT status
)

if !isdir("git_heads")
    try
        mkdir("git_heads")
    catch e
    end
end

writedlm("git_heads/git_heads_$(exp_nb).dat", git_heads)

@assert begin
    (!α_Θ_exps || isdir("heatmaps/data")) &&
        (!β_crit_exps || isdir("heatmaps/data")) &&
        (!ρ_β_exps || isdir("ldata")) &&
        (!ρ_t_exps || isdir("tdata"))
end "Folder structure is not properly initialised"

if α_Θ_exps
    println("α_Θ experiments: ")
    @time α_Θ(α_Θ_params, exp_nb)
end

if β_crit_exps
    println("βᶜ experiments: ")
    @time β_crit(β_crit_params, exp_nb)
end

if ρ_β_exps
    println("ρ(β) experiments: ")
    @time ρ_β(ρ_β_params, exp_nb)
end

if ρ_t_exps
    println("ρ(t) experiments: ")
    @time ρ_t(ρ_t_params, exp_nb)
end
