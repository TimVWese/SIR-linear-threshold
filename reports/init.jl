using General
using Graphs
using Logging

function preinit(experiment)
    include(experiment * "/setup.jl")
    cd(experiment)
    @assert experiment == name "Experiment name does not match!"
    rm("heatmaps", force=true, recursive=true)
    rm("ldata", force=true, recursive=true)
    rm("tdata", force=true, recursive=true)
    rm("git_heads", force=true, recursive=true)
    rm("externalize", force=true, recursive=true)
    rm("main.tex", force=true)
end

function initialise(Nb_networks, epi, epi_small, multiplex, opi=nothing, opi_small=nothing)
    mkdir("heatmaps")
    mkdir("heatmaps/data")
    mkdir("ldata")
    mkdir("tdata")
    mkdir("git_heads")
    mkdir("externalize")


    # generate and write out the networks
    if !("graph_data" in readdir())
        mkdir("graph_data")
        for i in 1:Nb_networks
            write_to_mtx("graph_data/epi_" * string(i) * ".mtx", epi())
            write_to_mtx("graph_data/epi_small_" * string(i) * ".mtx", epi_small())
            if multiplex
                write_to_mtx("graph_data/opi_" * string(i) * ".mtx", opi())
                write_to_mtx("graph_data/opi_small_" * string(i) * ".mtx", opi_small())
            end
        end
    end
end

if length(ARGS) == 0
    try
        include("setup.jl")
        mkdir(name)
        cd(name)
        cp("../setup.jl", "setup.jl")
    catch e
        if typeof(e) in (LoadError, Base.IOError)
            @assert false "Experiment already exists!"
        end
    end

    if multiplex
        initialise(Nb_networks, network_epi, network_epi_small, multiplex, network_opi, network_opi_small)
    else
        initialise(Nb_networks, network_epi, network_epi_small, multiplex)
    end
elseif length(ARGS) == 1 && ARGS[1] != "all"
    arg_name = ARGS[1][end] == '/' ? ARGS[1][1:end-1] : ARGS[1]
    try
        preinit(arg_name)
    catch e
        @assert "Problem in experiment $arg_name defintion!"
    end

    if multiplex
        initialise(Nb_networks, network_epi, network_epi_small, multiplex, network_opi, network_opi_small)
    else
        initialise(Nb_networks, network_epi, network_epi_small, multiplex)
    end
else
    const global IGNORE = ("latex", "finalise.jl", "init.jl", "report.pbs", "run.jl", "setup.jl")
    experiments = length(ARGS) == 1 ? filter(x -> !(x in IGNORE), readdir()) : ARGS
    for experiment in experiments
        if experiment[end] == '/'
            experiment = experiment[1:end-1]
        end
        try
            preinit(experiment)
        catch e
            @warn "No setup file found for experiment $experiment"
            println(e)
            continue
        end

        if multiplex
            initialise(Nb_networks, network_epi, network_epi_small, multiplex, network_opi, network_opi_small)
        else
            initialise(Nb_networks, network_epi, network_epi_small, multiplex)
        end
        cd("..")
    end
end
