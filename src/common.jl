
function tostr(val::UInt64)
    hval = uint32(val>>32)
    lval = uint32(val&0xffff_ffff)
    string(tostr(hval),tostr(lval))
end

function tostr(val::UInt32)
    string(char(val>>24), char((val>>16)&0xff), char((val>>8)&0xff), char(val&0xff))
end

function toval64(str::AbstractString)
    @assert(length(str)==8, length(str))
    hval = toval32(str[1:4])
    lval = toval32(str[5:8])
    uint64(hval)<<32|uint64(lval)
end

function toval32(str::AbstractString)
    @assert(length(str)==4)
    uint32(str[1])<<24|uint32(str[2])<<16|uint32(str[3])<<8|uint32(str[4])
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
