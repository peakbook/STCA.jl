module STCA

export CellSpace, Rule
export save, load, update!, get_state

include("rule.jl")
include("cellspace.jl")

const loadfuncs = [:CellSpace=>load_cell, :Rule=>load_rule]
function load(fname::String, typ::Symbol)
    if haskey(loadfuncs, typ)
        loadfuncs[typ](fname)
    end
end

end # module
