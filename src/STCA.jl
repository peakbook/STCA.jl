module STCA
using Compat
import Base.show
import Base.print
import Base.println

export CellSpace, Rule
export save, load, update!, get_state

include("rule.jl")
include("cellspace.jl")
include("common.jl")

end # module
