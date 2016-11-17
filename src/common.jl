
@inline function tostr(val::UInt64)
    hval = UInt32(val>>32)
    lval = UInt32(val&0xffff_ffff)
    string(tostr(hval),tostr(lval))
end

@inline function tostr(val::UInt32)
    string((Char(val>>24)), (Char((val>>16)&0xff)), (Char((val>>8)&0xff)), (Char(val&0xff)))
end

@inline function toval64(str::AbstractString)
    @assert(length(str)==8, length(str))
    hval = toval32(str[1:4])
    lval = toval32(str[5:8])
    UInt64(hval)<<32|UInt64(lval)
end

@inline function toval32(str::AbstractString)
    @assert(length(str)==4)
    UInt32(str[1])<<24|UInt32(str[2])<<16|UInt32(str[3])<<8|UInt32(str[4])
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
