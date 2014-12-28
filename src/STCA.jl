module STCA
using Compat
import Base.show
import Base.print
import Base.println

export CellSpace, Rule
export save, load, update!, get_state

include("common.jl")
include("rule.jl")
include("cellspace.jl")

const loadfuncs = @compat Dict(:CellSpace=>load_cell, :Rule=>load_rule)
function load(fname::String, typ::Symbol)
    if haskey(loadfuncs, typ)
        loadfuncs[typ](fname)
    end
end

end # module
