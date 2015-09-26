
@inline function tostr(val::UInt64)
    hval = @compat UInt32(val>>32)
    lval = @compat UInt32(val&0xffff_ffff)
    string(tostr(hval),tostr(lval))
end

@inline function tostr(val::UInt32)
    string((@compat Char(val>>24)), (@compat Char((val>>16)&0xff)), (@compat Char((val>>8)&0xff)), (@compat Char(val&0xff)))
end

@inline function toval64(str::AbstractString)
    @assert(length(str)==8, length(str))
    hval = toval32(str[1:4])
    lval = toval32(str[5:8])
    @compat UInt64(hval)<<32|@compat UInt64(lval)
end

@inline function toval32(str::AbstractString)
    @assert(length(str)==4)
    @compat UInt32(str[1])<<24|@compat UInt32(str[2])<<16|@compat UInt32(str[3])<<8|@compat UInt32(str[4])
end

const loadfuncs = @compat Dict(:CellSpace=>load_cell, :Rule=>load_rule)
function load(fname::String, typ::Symbol)
    if haskey(loadfuncs, typ)
        loadfuncs[typ](fname)
    else
        throw("no function for $typ")
    end
end

const updatefuncs = @compat Dict(:Checkerboard=>update_checkerboard!, :Random=>update_random!)
function update!(cs::CellSpace, rule::Rule, typ::Symbol)
    if haskey(updatefuncs, typ)
        updatefuncs[typ](cs, rule)
    else
        throw("no function for $typ")
    end
end
