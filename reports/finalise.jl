using Graphs, Plots
using DelimitedFiles
using Logging

grid = Graphs.grid
pgfplotsx()

# shouldn't be touched usually
const global HEATMAP_SIZE = (290, 270)

heatplot = (data, params; rescale=1.0, clim=(0, 1)) -> heatmap(
    params.xs,
    params.ys,
    data' .* rescale;
    xlabel=params.xlabel,
    ylabel=params.ylabel,
    aspect_ratio=:equal,
    size=HEATMAP_SIZE,
    clim=clim
)

include("latex/latex.jl")
include("plots.jl")

function α_Θ(params, nb_exps)
    Rs = zeros(length(params.xs), length(params.ys))
    As = zeros(length(params.xs), length(params.ys))
    Ts = zeros(length(params.xs), length(params.ys))

    for i in 1:nb_exps
        Rs += readdlm("heatmaps/data/Rs_$i.dat") / nb_exps
        As += readdlm("heatmaps/data/As_$i.dat") / nb_exps
        Ts += readdlm("heatmaps/data/Ts_$i.dat") / nb_exps
    end

    heatsave(heatplot(Rs, params), "heatmaps/Rs.tex", params.prec)
    heatsave(heatplot(As, params), "heatmaps/As.tex", params.prec)
    heatsave(heatplot(Ts, params; clim=(0, params.Tₑ)), "heatmaps/Ts.tex", params.prec)

    writedlm("heatmaps/data/Rs.dat", Rs)
    writedlm("heatmaps/data/As.dat", As)
    writedlm("heatmaps/data/Ts.dat", Ts)

    if params.extended
        βs = zeros(length(params.xs), length(params.ys))
        max_Is = zeros(length(params.xs), length(params.ys))
        T_mIs = zeros(length(params.xs), length(params.ys))
        max_As = zeros(length(params.xs), length(params.ys))
        T_mAs = zeros(length(params.xs), length(params.ys))

        for i in 1:nb_exps
            βs += readdlm("heatmaps/data/bs_$i.dat") / nb_exps
            max_Is += readdlm("heatmaps/data/max_Is_$i.dat") / nb_exps
            T_mIs += readdlm("heatmaps/data/T_mIs_$i.dat") / nb_exps
            max_As += readdlm("heatmaps/data/max_As_$i.dat") / nb_exps
            T_mAs += readdlm("heatmaps/data/T_mAs_$i.dat") / nb_exps
        end

        heatsave(heatplot(βs, params; clim=(0, 1)), "heatmaps/bs.tex", params.prec)
        heatsave(heatplot(max_Is, params; clim=(0, params.max_I_hm_lim)), "heatmaps/max_Is.tex", params.prec)
        heatsave(heatplot(T_mIs, params; clim=(0, params.max_T_hm_lim)), "heatmaps/T_mIs.tex", params.prec)
        heatsave(heatplot(max_As, params; clim=(0, params.max_A_hm_lim)), "heatmaps/max_As.tex", params.prec)
        heatsave(heatplot(T_mAs, params; clim=(0, params.max_T_hm_lim)), "heatmaps/T_mAs.tex", params.prec)

        writedlm("heatmaps/data/bs.dat", βs)
        writedlm("heatmaps/data/max_Is.dat", max_Is)
        writedlm("heatmaps/data/T_mIs.dat", T_mIs)
        writedlm("heatmaps/data/max_As.dat", max_As)
        writedlm("heatmaps/data/T_mAs.dat", T_mAs)
    end
end

function β_crit(params, nb_exps)
    for ρ in params.ρs
        id = string(ρ)[3:end]
        βs = zeros(length(params.xs), length(params.ys))
        for i in 1:nb_exps
            βs += readdlm("heatmaps/data/bc$(id)_$i.dat") / nb_exps
        end
        heatsave(heatplot(βs, params), "heatmaps/bc" * id * ".tex", params.prec)
        writedlm("heatmaps/data/bc" * id * ".dat", βs)
    end
end

function ρ_β(params, nb_exps)
    Rs = zeros(length(params.xs) + 1, length(params.βs))'
    As = zeros(length(params.xs) + 1, length(params.βs))'

    for i in 1:nb_exps
        Rs += readdlm("ldata/Rs_$i.dat") / nb_exps
        As += readdlm("ldata/As_$i.dat") / nb_exps
    end

    writedlm("ldata/Rs.dat", Rs)
    writedlm("ldata/As.dat", As)
end

function ρ_t(params, nb_exps)

    Is = zeros(params.Tₑ, length(params.xs) + 1)
    As = zeros(params.Tₑ, length(params.xs) + 1)

    for i in 1:nb_exps
        Is += readdlm("tdata/Rs_$i.dat") / nb_exps
        As += readdlm("tdata/As_$i.dat") / nb_exps
    end

    f_idx = findfirst(sum(Is, dims=2) .< 1e-3)
    idx = f_idx === nothing ? params.Tₑ : f_idx[1]

    writedlm("tdata/Rs.dat", Is[1:idx, :])
    writedlm("tdata/As.dat", As[1:idx, :])
end

function mmca_ρ(params, nb_exps)

    Rs = zeros(length(params.xs) + 1, length(params.βs))'
    As = zeros(length(params.xs) + 1, length(params.βs))'

    for i in 1:nb_exps
        Rs += readdlm("ldata/Rs_mmca_$i.dat") / nb_exps
        As += readdlm("ldata/As_mmca_$i.dat") / nb_exps
    end

    writedlm("ldata/Rs_mmca.dat", Rs)
    writedlm("ldata/As_mmca.dat", As)
end

if length(ARGS) == 1
    experiment = ARGS[1][end] == '/' ? ARGS[1][1:end-1] : ARGS[1]
    for_exp = " for experiment $experiment"
    try
        include(experiment * "/setup.jl")
        cd(experiment)
    catch e
        @warn "No setup file found"*for_exp
        println(e)
        exit()
    end

    git_heads_raw = readdlm("git_heads/git_heads_1.dat")
    git_heads = (
        project=git_heads_raw[1],
        General=git_heads_raw[2],
        LuMV=git_heads_raw[3],
        LuMV_status=git_heads_raw[4],
    )

    for i in 2:Nb_networks
        other_gh = readdlm("git_heads/git_heads_$i.dat")
        and_netw = for_exp*" and network $i"
        @assert git_heads.project == other_gh[1] "Project head differs over networks"*and_netw
        @assert git_heads.General == other_gh[2] "General head differs over networks"*and_netw
        @assert git_heads.LuMV == other_gh[3] "LuMV head differs over networks"*and_netw
        @assert git_heads.LuMV_status == other_gh[4] "LuMV status differs over networks"*and_netw
    end

    if α_Θ_exps
        α_Θ(α_Θ_params, Nb_networks)
    end

    if β_crit_exps
        β_crit(β_crit_params, Nb_networks)
    end

    if ρ_β_exps
        ρ_β(ρ_β_params, Nb_networks)
    end

    if ρ_t_exps
        ρ_t(ρ_t_params, Nb_networks)
    end

    if mmca_exps
        @assert ρ_β_exps "mmca, without baseline things will break"*for_exp
        mmca_ρ(mmca_params, Nb_networks)
    end

    try
        mkdir("externalize")
    catch
    end
    generate_latex_document(
        title, name, git_heads, α_Θ_exps, β_crit_exps,
        ρ_β_exps, ρ_t_exps, mmca_exps;
        α_Θ_extended=α_Θ_params.extended,
        β_ρs=β_crit_params.ρs,
        ρ_β_xs=ρ_β_params.xs,
        ρ_β_xlabel=ρ_β_params.xlabel,
        ρ_t_xs=ρ_t_params.xs,
        ρ_t_xlabel=ρ_t_params.xlabel
    )
    read(`pdflatex -synctex=1 -interaction=nonstopmode -shell-escape $experiment.tex`)
else
    const global IGNORE = ("latex", "finalise.jl", "init.jl", "report.pbs", "run.jl", "setup.jl")
    experiments = length(ARGS) == 0 ? filter(x -> !(x in IGNORE), readdir()) : ARGS

    nb_done = Threads.Atomic{Int}(0)
    Threads.@threads for experiment in experiments
        run(`julia finalise.jl $experiment`)
        Threads.atomic_add!(nb_done, 1)
        @info "Done with experiment $experiment, $(nb_done[]) out of $(length(experiments)) done"
    end
end
