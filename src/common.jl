
function tostr(val::Uint64)
    hval = uint32(val>>32)
    lval = uint32(val)
    string(tostr(hval),tostr(lval))
end

function tostr(val::Uint32)
    string(char(val>>24), char((val>>16)&0xff), char((val>>8)&0xff), char(val&0xff))
end

function toval64(str::String)
    @assert(length(str)==8, length(str))
    hval = toval32(str[1:4])
    lval = toval32(str[5:8])
    uint64(hval)<<32|uint64(lval)
end

function toval32(str::String)
    @assert(length(str)==4)
    uint32(str[1])<<24|uint32(str[2])<<16|uint32(str[3]<<8)|uint32(str[4])
end