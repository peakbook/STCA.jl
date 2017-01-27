type CellSpace
    cells::Array{Cell,2} # cell array
    width::Integer         # cell space width
    height::Integer        # cell space height
    function CellSpace(w::Integer, h::Integer)
        cells = zeros(Cell, w, h)
        new(cells, w, h)
    end
    function CellSpace(cells::Array{Cell,2})
        w = size(cells, 1)
        h = size(cells, 2)
        new(cells, w, h)
    end
end

# 0x11223344 <-> 0xNNEESSWW
@inline function north(val::Cell)
    (val >> BSHIFT_NORTH) & BMASK_P
end
@inline function east(val::Cell)
    (val >> BSHIFT_EAST) & BMASK_P
end
@inline function south(val::Cell)
    (val >> BSHIFT_SOUTH) & BMASK_P
end
@inline function west(val::Cell)
    (val >> BSHIFT_WEST) & BMASK_P
end


@inline function qn(d::SubArray)
    Transition(south(d[QNORTH_IDX]))
end
@inline function qe(d::SubArray)
    Transition(west(d[QEAST_IDX]))
end
@inline function qs(d::SubArray)
    Transition(north(d[QSOUTH_IDX]))
end
@inline function qw(d::SubArray)
    Transition(east(d[QWEST_IDX]))
end


@inline function qn!(d::SubArray, val::Cell)
    d[QNORTH_IDX] = (d[QNORTH_IDX] & ~BMASK_SOUTH)|(val << BSHIFT_SOUTH)
end
@inline function qe!(d::SubArray, val::Cell)
    d[QEAST_IDX] = (d[QEAST_IDX] & ~BMASK_WEST)|(val << BSHIFT_WEST)
end
@inline function qs!(d::SubArray, val::Cell)
    d[QSOUTH_IDX] = (d[QSOUTH_IDX] & ~BMASK_NORTH)|(val << BSHIFT_NORTH)
end
@inline function qw!(d::SubArray, val::Cell)
    d[QWEST_IDX] = (d[QWEST_IDX] & ~BMASK_EAST)|(val << BSHIFT_EAST)
end

function get_target_state(d::SubArray)
    (Transition(d[TARGET_IDX]) << BSHIFT_CELL) |
    (qn(d) << BSHIFT_NORTH) |
    (qe(d) << BSHIFT_EAST) |
    (qs(d) << BSHIFT_SOUTH) |
    (qw(d) << BSHIFT_WEST)
end

function set_target_state(d::SubArray, val::Transition)
    hval = Cell(val >> BSHIFT_CELL)
    lval = Cell(val & BMASK_C)
    d[TARGET_IDX] = hval
    qn!(d, north(lval))
    qe!(d, east(lval))
    qs!(d, south(lval))
    qw!(d, west(lval))
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

function transition(key::Transition, rule)
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
    if !reduce(&, map(x->ismatch(r"^[0-9a-zA-Z]{4,4}$",x), tcells))
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

