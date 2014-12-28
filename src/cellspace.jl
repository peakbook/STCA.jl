
type CellSpace
    cells::Array{UInt32,2} # cell array
    width::Integer         # cell space width
    height::Integer        # cell space height
    idx::(Array,Array)     # checkerboard indices for update
    function CellSpace(w::Integer, h::Integer)
        cells = zeros(UInt32, w, h)
        idx = genidx(w, h)
        new (cells, w, h, idx)
    end
    function CellSpace(cells::Array{UInt32,2})
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

# 0x11223344 <-> 0xNNEESSWW
function north(val::UInt32)
    val>>24
end
function east(val::UInt32)
    (val>>16)&0x0000_00ff
end
function south(val::UInt32)
    (val>>8)&0x0000_00ff
end
function west(val::UInt32)
    val&0x0000_00ff
end


# subarray indices
# [1][4][7]
# [2][5][8]
# [3][6][9]
function qn(d::SubArray)
    uint64(south(d[4]))
end
function qe(d::SubArray)
    uint64(west(d[8]))
end
function qs(d::SubArray)
    uint64(north(d[6]))
end
function qw(d::SubArray)
    uint64(east(d[2]))
end


function qn(d::SubArray, val::UInt32)
    d[4] = (d[4]&0xffff_00ff)|(val<<8)
end
function qe(d::SubArray, val::UInt32)
    d[8] = (d[8]&0xffff_ff00)|(val)
end
function qs(d::SubArray, val::UInt32)
    d[6] = (d[6]&0x00ff_ffff)|(val<<24)
end
function qw(d::SubArray, val::UInt32)
    d[2] = (d[2]&0xff00_ffff)|(val<<16)
end

function get_target_state(d::SubArray)
    uint64(d[5])<<32|qn(d)<<24|qe(d)<<16|qs(d)<<8|qw(d)
end

function set_target_state(d::SubArray, val::UInt64)
    hval = uint32(val>>32)
    lval = uint32(val)
    d[5] = hval
    qn(d, north(lval))
    qe(d, east(lval))
    qs(d, south(lval))
    qw(d, west(lval))
end

idx_update=0
function update!(cellspace::CellSpace, rule::Rule)
    # update cell space with checkerboard pattern
    global idx_update
    for idx in cellspace.idx[idx_update+1]
        update!(cellspace, rule, idx[1], idx[2])
    end
    idx_update= (idx_update+1)%2
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

function transition(key::UInt64, rule)
    if haskey(rule.dict, key)
        rule.dict[key][1], true
    else
        key, false
    end
end

function save(fname::AbstractString, cs::CellSpace)
    cells = map(tostr, cs.cells)
    writedlm(fname, cells, ' ')
end

function load_cell(fname::AbstractString)
    cells = map(toval32, readdlm(fname,AbstractString))
    CellSpace(cells)
end

function get_state(cs::CellSpace, x::Integer, y::Integer, typ::Symbol)
    # typ is expected to be :north, :souch, :east, and :west
    eval(typ)(cs.cells[x, y])
end

function get_state(cs::CellSpace, x::Integer, y::Integer)
    cs.cells[x, y]
end

function show(io::IO, cs::CellSpace)
    cells = map(tostr, cs.cells)
    writedlm(io, cells, ' ')
end

function print(cs::CellSpace)
    show(STDOUT, cs)
end

function println(cs::CellSpace)
    show(STDOUT, cs)
    println()
end

