using Plots

function heatsave(hm::Plots.Plot, filename::String, prec=Dict();type="")
    pgfplotsx()
    savefig(hm, filename)
    if type==""
        type = filename[end-5:end-4]
    end
    if haskey(prec, type)
        p, dim, occ = prec[type]
        addp = x->add_precision(x; precision=p, dim=dim, occ=occ)
    else
        addp = x->x
    end
    apply_cleanup(filename, remove_preamble, defonttex, addp, structurize)
end

##################
# TikZ clean-up
##################

function closing_index(content, start)
    open = content[start]
    @assert open == '{' || open == '['
    close = open == '{' ? '}' : ']'
    c_i = start
    nb_opened = 1
    while nb_opened > 0
        c_i += 1
        if content[c_i] == open
            nb_opened += 1
        elseif content[c_i] == close
            nb_opened -= 1
        end
    end
    return c_i
end

function apply_cleanup(file::String, ops...)
    content = read(file, String)
    for op in ops
        content = op(content)
    end
    write(file, content)
end

function remove_indentation(content::String; ind=4)::String
    return content[[i for i in eachindex(content) if !(i in vcat(collect.(findall(" "^ind, content))...))]]
end

function defonttex(content::String)::String
    fs = findall("font=", content)

    for f in fs[end:-1:1]
        c_i = closing_index(content, f[end]+1)
        e = length(content) > c_i+2 && content[c_i+1:c_i+2] == ", " ?  e = c_i + 3 : e = c_i + 1
        content = content[1:f[1]-1]*content[e:end]
    end
    return content
end

function remove_preamble(content::String)::String
    i = findfirst("\\begin", content)
    return content[i[1]:end]
end

function break_blocks(content::String, pattern::String)::String
    i = findfirst(pattern, content)[end]
    while i < length(content)
        if (content[i+1] != '\n')
            c = closing_index(content, i)
            comma = findnext(r",[ \n]", content, i)
            if comma !== nothing && comma[end] < c
                content = content[1:i]*"\n"*content[i+1:c-1]*"\n"*content[c:end]
            end
            i = findnext(pattern, content, i+1)
            i = i === nothing ? length(content) + 1 : i[end]
        end
    end
    return content
end

function indent_blocks(content::String; ind=2)::String
    nb = 0

    for i in length(content)-1:-1:1
        char = content[i]
        add = false
        if char == '{' || char == '['
            nb -= 1
        elseif char == '\n'
            if content[i+1] == '}' || content[i+1] == ']'
                add = true
            end
            content = content[1:i]*(" "^(ind*nb))*content[i+1:end]
        end
        if add || content[i+1] == '}' || content[i+1] == ']'
            nb += 1
        end
    end
    return content
end

function structurize(content::String; ind=2)::String
    content = remove_indentation(content)

    commas = findall(", ", content)
    for comma in commas[end:-1:1]
        content = content[1:comma[1]]*"\n"*content[comma[2]+1:end]
    end

    content = break_blocks(content, "[")
    content = break_blocks(content, "={")
    return indent_blocks(content; ind=ind)
end

function add_precision(content::String; precision=2, dim="x", occ=1)::String
    precision_string = ", /pgf/number format/fixed, /pgf/number format/precision="*string(precision)
    fs = findall(dim*"ticklabel style={", content)
    @assert length(fs) >= occ
    f = fs[occ]
    c_i = closing_index(content, f[end])
    return content[1:c_i-1]*precision_string*content[c_i:end]
end

function change_ticklabels(content::String; dim="x", new_label="", occ=1)::String
    fs = findall(dim*"ticklabels={", content)
    @assert length(fs) >= occ
    f = fs[occ]
    c_i = closing_index(content, f[end])
    return content[1:f[end]]*new_label*content[c_i:end]
end
