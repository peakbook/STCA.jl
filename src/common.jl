
@inline function tostr(val::Transition)
    hval = Cell(val >> BSHIFT_CELL)
    lval = Cell(val & BMASK_C)
    string(tostr(hval),tostr(lval))
end

@inline function tostr(val::Cell)
    string((Char((val >> BSHIFT_NORTH) & BMASK_P)),
           (Char((val >> BSHIFT_EAST) & BMASK_P)),
           (Char((val >> BSHIFT_SOUTH) & BMASK_P)),
           (Char((val >> BSHIFT_WEST) & BMASK_P)))
end

@inline function toval64(str::AbstractString)
    @assert(length(str)==sizeof(UInt64), length(str))
    hval = toval32(str[1:4])
    lval = toval32(str[5:8])
    Transition(hval) << BSHIFT_CELL|Transition(lval)
end

@inline function toval32(str::AbstractString)
    @assert(length(str)==sizeof(UInt32))
    Cell(str[1]) << BSHIFT_NORTH|
    Cell(str[2]) << BSHIFT_EAST|
    Cell(str[3]) << BSHIFT_SOUTH|
    Cell(str[4]) << BSHIFT_WEST
end

const loadfuncs = Dict(:CellSpace=>load_cell, :Rule=>load_rule)
function load(fname::String, typ::Symbol)
    if haskey(loadfuncs, typ)
        loadfuncs[typ](fname)
    else
        throw("no function for $typ")
    end
end

const updatefuncs = Dict(:Checkerboard=>update_checkerboard!, :Random=>update_random!)
function update!(cs::CellSpace, rule::Rule, typ::Symbol)
    if haskey(updatefuncs, typ)
        updatefuncs[typ](cs, rule)
    else
        throw("no function for $typ")
    end
end
