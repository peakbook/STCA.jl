
type CellSpace
    cells::Array{Uint16,2}
    width::Integer
    height::Integer
    idx1::Array
    idx2::Array
    function CellSpace(w::Integer, h::Integer)
        cells = zeros(Uint32, w, h)
        idx1, idx2 = genidx(w,h)
        new (cells, w, h, idx1, idx2)
    end
    function CellSpace(cells::Array{Uint16,2})
        w = size(cells,1)
        h = size(cells,2)
        idx1, idx2 = genidx(w,h)
        new (cells, w, h, idx1, idx2)
    end
end

function genidx(w,h)
    idx1 = (Int32,Int32)[]
    for i=3:2:w-1, j=3:2:h-1
        push!(idx1,(i,j))
    end
    for i=2:2:w-1, j=2:2:h-1
        push!(idx1,(i,j))
    end
    sort!(idx1)

    idx2 = (Int32,Int32)[]
    for i=2:2:w-1, j=3:2:h-1
        push!(idx2,(i,j))
    end
    for i=3:2:w-1, j=2:2:h-1
        push!(idx2,(i,j))
    end
    sort!(idx2)
    idx1, idx2
end

function north(val::Uint16)
    val>>12
end
function east(val::Uint16)
    (val>>8)&0x000f
end
function south(val::Uint16)
    (val>>4)&0x000f
end
function west(val::Uint16)
    val&0x000f
end

function qn(d::SubArray)
    uint32(south(d[4]))
end
function qe(d::SubArray)
    uint32(west(d[8]))
end
function qs(d::SubArray)
    uint32(north(d[6]))
end
function qw(d::SubArray)
    uint32(east(d[2]))
end

function qn(d::SubArray, val::Uint16)
    d[4] = (d[4]&0xff0f)|(north(val)<<4)
end
function qe(d::SubArray, val::Uint16)
    d[8] = (d[8]&0xfff0)|(east(val))
end
function qs(d::SubArray, val::Uint16)
    d[6] = (d[6]&0x0fff)|(south(val)<<12)
end
function qw(d::SubArray, val::Uint16)
    d[2] = (d[2]&0xf0ff)|(west(val)<<8)
end

function getstate(d::SubArray)
    uint32(uint32(d[5])<<16|qn(d)<<12|qe(d)<<8|qs(d)<<4|qw(d))
end

function setstate(d::SubArray, state::Uint32)
    hs = uint16(state>>16)
    ls = uint16(state)
    d[5] = hs
    qn(d, ls)
    qe(d, ls)
    qs(d, ls)
    qw(d, ls)
end

function update!(cellspace::CellSpace, rule::Rule)
    for idx in cellspace.idx1
        update!(cellspace, rule, idx[1], idx[2])
    end
    for idx in cellspace.idx2
        update!(cellspace, rule, idx[1], idx[2])
    end
end

function update!(cellspace::CellSpace, rule::Rule, x::Integer, y::Integer)
    # get local cells
    sfd = sub(cellspace.cells, x-1:x+1, y-1:y+1)

    # get current state of (x,y)
    state = getstate(sfd)

    # transition
    state,flag = transition(state, rule)

    # set state
    setstate(sfd, state)

    flag
end

function transition(key::Uint32, rule)
    if haskey(rule.list, key)
        rule.list[key], true
    else
        # no rule
        key, false
    end
end

function tohexstr(val::Uint16)
    hex(val,4)
end

function tohex(str::String)
    uint16(string("0x",str))
end

function save(fname::String, cellspace::CellSpace)
    cells = map(tohexstr, cellspace.cells)
    writedlm(fname, cells, ' ')
end

function load_cell(fname::String)
    cells = map(tohex, readdlm(fname,String))
    CellSpace(cells)
end

