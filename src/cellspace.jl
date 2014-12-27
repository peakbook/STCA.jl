
type CellSpace
    cells::Array{Uint16,2} # cell array
    width::Integer         # cell space width
    height::Integer        # cell space height
    idx::(Array,Array)     # checkerboard indices for update
    function CellSpace(w::Integer, h::Integer)
        cells = zeros(Uint32, w, h)
        idx = genidx(w, h)
        new (cells, w, h, idx)
    end
    function CellSpace(cells::Array{Uint16,2})
        w = size(cells, 1)
        h = size(cells, 2)
        idx = genidx(w, h)
        new (cells, w, h, idx)
    end
end

function genidx(w,h)
    idx1 = (Integer,Integer)[]
    for i=3:2:w-1, j=3:2:h-1
        push!(idx1,(i,j))
    end
    for i=2:2:w-1, j=2:2:h-1
        push!(idx1,(i,j))
    end
    sort!(idx1)

    idx2 = (Integer,Integer)[]
    for i=2:2:w-1, j=3:2:h-1
        push!(idx2,(i,j))
    end
    for i=3:2:w-1, j=2:2:h-1
        push!(idx2,(i,j))
    end
    sort!(idx2)

    idx1, idx2
end

# 0x1234 <-> 0xNESW
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


# subarray indices
# [1][4][7]
# [2][5][8]
# [3][6][9]
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
    d[4] = (d[4]&0xff0f)|(val<<4)
end
function qe(d::SubArray, val::Uint16)
    d[8] = (d[8]&0xfff0)|(val)
end
function qs(d::SubArray, val::Uint16)
    d[6] = (d[6]&0x0fff)|(val<<12)
end
function qw(d::SubArray, val::Uint16)
    d[2] = (d[2]&0xf0ff)|(val<<8)
end

function get_target_state(d::SubArray)
    uint32(d[5])<<16|qn(d)<<12|qe(d)<<8|qs(d)<<4|qw(d)
end

function set_target_state(d::SubArray, val::Uint32)
    hval = uint16(val>>16)
    lval = uint16(val)
    d[5] = hval
    qn(d, north(lval))
    qe(d, east(lval))
    qs(d, south(lval))
    qw(d, west(lval))
end

function update!(cellspace::CellSpace, rule::Rule)
    # update cell space with checkerboard pattern
    for idx1 in cellspace.idx[1]
        update!(cellspace, rule, idx1[1], idx1[2])
    end
    for idx2 in cellspace.idx[2]
        update!(cellspace, rule, idx2[1], idx2[2])
    end
end

function update!(cellspace::CellSpace, rule::Rule, x::Integer, y::Integer)
    # get 3x3 neighbor cells array
    ncells = sub(cellspace.cells, x-1:x+1, y-1:y+1)

    # get current state of (x,y)
    state = get_target_state(ncells)

    # transition
    state,flag = transition(state, rule)

    # set state
    set_target_state(ncells, state)

    flag
end

function transition(key::Uint32, rule)
    if haskey(rule.dict, key)
        rule.dict[key][1], true
    else
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

function get_state(cs::CellSpace, x::Integer, y::Integer, typ::Symbol)
    # typ is expected to be :north, :souch, :east, and :west
    eval(typ)(cs.cells[x, y])
end

function get_state(cs::CellSpace, x::Integer, y::Integer)
    cs.cells[x, y]
end

