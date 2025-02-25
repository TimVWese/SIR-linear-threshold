
function start_crit_fig(indent)
    content = indent*"\\begin{figure}[h]\n"
    indent = indent*"  "
    content = content*indent*"\\centering\n"*indent*"\n"*indent*"\\hspace{-17pt}\n"
    return content, indent
end

function end_crit_fig(indent)
    indent = indent[3:end]
    return indent*"\\end{figure}\n\n", indent
end

const global GIT_URL = "https://github.com/TimVWese/"
const global PROJECT_URL = GIT_URL*"overleaf/tree/"
const global GENERAL_URL = GIT_URL*"General.jl/tree/"
const global LUMV_URL = GIT_URL*"LuMV.jl/tree/"

git_url(url, commit) = "\\href{$url$commit}{\\texttt{$commit}}"

function git_status_section(indent, git_heads)
    content = indent*"\\section{Git}\n"*indent*"\\begin{itemize}\n"
    indent = indent*"  "
    content = content*indent*"\\item HEAD project: "*git_url(PROJECT_URL, git_heads.project)*"\n"
    content = content*indent*"\\item HEAD General: "*git_url(GENERAL_URL, git_heads.General)*"\n"
    content = content*indent*"\\item HEAD LuMV: "*git_url(LUMV_URL, git_heads.LuMV)*"\n"
    content = content*indent*"\\item Status LuMV: \\\\\\texttt{"*replace(git_heads.LuMV_status, "_"=>"\\_", "\n"=>"\\\\")*"}\n"
    indent = indent[1:end-2]
    content = content*indent*"\\end{itemize}\n\n"
   return content
end

function generate_latex_document(
    title, name, git_heads, α_Θ_enabled, β_crit_enabled, ρ_β_enabled, ρ_ω_enabled, ρ_t_enabled;
    α_Θ_extended=false, β_ρs=[], ρ_β_xs=[], ρ_β_xlabel="", ρ_ω_xs=[], ρ_ω_xlabel="",ρ_t_xs=[], ρ_t_xlabel=""
)
    main = read("../latex/prefix.textemp", String)*"\n"
    suf = "\\end{document}\n"
    indent = "  "

    nb_β_xs = string(length(ρ_β_xs))
    nb_ω_xs = string(length(ρ_ω_xs))

    main = replace(main,
        "TITLE"=>title,
        "NBBXS"=>nb_β_xs,
        "RHOBXLABEL"=>ρ_β_xlabel,
        "RHOBXS"=>string(collect(ρ_β_xs))[2:end-1],
        "NBOXS"=>nb_ω_xs,
        "RHOOXLABEL"=>ρ_ω_xlabel,
        "RHOOXS"=>string(collect(ρ_ω_xs))[2:end-1],
        "NTXS"=>string(length(ρ_t_xs)),
        "RHOTXLABEL"=>ρ_t_xlabel,
        "RHOTXS"=>string(collect(ρ_t_xs))[2:end-1],
        "MMCAA"=>"",
        "MMCAR"=>"",
    )

    main = α_Θ_extended ?
        replace(main,
            "BETASSUBFIG"=>"\\betassubfig",
            "TEMPORALFIGS"=>"\\temporalfigs"
        ) : 
        replace(main,
            "BETASSUBFIG"=>"",
            "TEMPORALFIGS"=>""
        )

    main = main*git_status_section(indent, git_heads)

    if α_Θ_enabled
        main = main*indent*"\\alphaThetaHms"*"\n\n"
    end

    if β_crit_enabled
        start, indent = start_crit_fig(indent)
        main = main*start
        hshift = "\\hspace{17pt}"
        for ρ in β_ρs
            hshift = (hshift == "\\hspace{17pt}") ? "\\hspace{-17pt}" : "\\hspace{17pt}" 
            main = main*indent*hshift*"\n"
            id = string(ρ)
            main = main*indent*"\\betaCrits{"*id[3:end]*"}{"*id*"}\n"
        end
        ending, indent = end_crit_fig(indent)
        main = main*ending
    end

    if ρ_β_enabled
        main = main*indent*"\\betafig"*"\n\n"
    end

    if ρ_β_enabled
        main = main*indent*"\\omegafig"*"\n\n"
    end

    if ρ_t_enabled
        main = main*indent*"\\timefig"*"\n\n"
    end

    write(name*".tex", main*suf)
end