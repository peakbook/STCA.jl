
type CellSpace
    cells::Array{UInt32,2} # cell array
    width::Integer         # cell space width
    height::Integer        # cell space height
    function CellSpace(w::Integer, h::Integer)
        cells = zeros(UInt32, w, h)
        new(cells, w, h)
    end
    function CellSpace(cells::Array{UInt32,2})
        w = size(cells, 1)
        h = size(cells, 2)
        new(cells, w, h)
    end
end

# 0x11223344 <-> 0xNNEESSWW
@inline function north(val::UInt32)
    val>>24
end
@inline function east(val::UInt32)
    (val>>16)&0x0000_00ff
end
@inline function south(val::UInt32)
    (val>>8)&0x0000_00ff
end
@inline function west(val::UInt32)
    val&0x0000_00ff
end


# subarray indices
# [1][4][7]
# [2][5][8]
# [3][6][9]
@inline function qn(d::SubArray)
    UInt64(south(d[4]))
end
@inline function qe(d::SubArray)
    UInt64(west(d[8]))
end
@inline function qs(d::SubArray)
    UInt64(north(d[6]))
end
@inline function qw(d::SubArray)
    UInt64(east(d[2]))
end


@inline function qn(d::SubArray, val::UInt32)
    d[4] = (d[4]&0xffff_00ff)|(val<<8)
end
@inline function qe(d::SubArray, val::UInt32)
    d[8] = (d[8]&0xffff_ff00)|(val)
end
@inline function qs(d::SubArray, val::UInt32)
    d[6] = (d[6]&0x00ff_ffff)|(val<<24)
end
@inline function qw(d::SubArray, val::UInt32)
    d[2] = (d[2]&0xff00_ffff)|(val<<16)
end

function get_target_state(d::SubArray)
    UInt64(d[5])<<32|qn(d)<<24|qe(d)<<16|qs(d)<<8|qw(d)
end

function set_target_state(d::SubArray, val::UInt64)
    hval = UInt32(val>>32)
    lval = UInt32(val&0xffff_ffff)
    d[5] = hval
    qn(d, north(lval))
    qe(d, east(lval))
    qs(d, south(lval))
    qw(d, west(lval))
end

function update_checkerboard!(cs::CellSpace, rule::Rule)
    w = cs.width-1
    h = cs.height-1

    @parallel for idx in [vec([(i,j) for i=3:2:w,j=3:2:h]);vec([(i,j) for i=2:2:w,j=2:2:h])]
        update!(cs, rule, idx[1], idx[2])
    end
    @parallel for idx in [vec([(i,j) for i=2:2:w,j=3:2:h]);vec([(i,j) for i=3:2:w,j=2:2:h])]
        update!(cs, rule, idx[1], idx[2])
    end
end

function update_random!(cs::CellSpace, rule::Rule)
    for idx in shuffle(vec([(i,j) for i=2:cs.width-1,j=2:cs.height-1]))
        update!(cs, rule, idx[1], idx[2])
    end
end

function update!(cs::CellSpace, rule::Rule, x::Integer, y::Integer)
    # get 3x3 neighbor cells array
    ncells = view(cs.cells, x-1:x+1, y-1:y+1)

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
    tcells = readdlm(fname,String)
    load_cell(tcells)
end

function load_cell(tcells::Array{String,2})
    if !reduce(&,map(x->ismatch(r"^[0-9a-zA-Z]{4,4}$",x), tcells))
        throw("cell data error.")
    end
    cells = map(toval32, tcells)
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

