__precompile__()

module STCA
import Base.show
import Base.print
import Base.println

export CellSpace, Rule
export save, load, update!, get_state

macro NBITS(typ)
    :(sizeof($typ)*8)
end

typealias Index UInt64
typealias Count UInt64
typealias Partition UInt8     # unit state
typealias Cell UInt32         # a cell has 4 partitions
typealias Transition UInt64   # target cell with its Neumann-neighbor cells

const NBITS_P = @NBITS(Partition)
const NBITS_C = @NBITS(Cell)
const NBITS_T = @NBITS(Transition)
const BMASK_P = typemax(Partition)
const BMASK_C = typemax(Cell)

# 0x11223344 <-> 0xNNEESSWW
const BSHIFT_CELL  = NBITS_C

# 0xNNEESSWW
const BSHIFT_WEST  = NBITS_P*0
const BSHIFT_SOUTH = NBITS_P*1
const BSHIFT_EAST  = NBITS_P*2
const BSHIFT_NORTH = NBITS_P*3

const BMASK_WEST  = Cell(Partition(BMASK_P)) << BSHIFT_WEST   # 0x0000_00ff
const BMASK_SOUTH = Cell(Partition(BMASK_P)) << BSHIFT_SOUTH  # 0x0000_ff00
const BMASK_EAST  = Cell(Partition(BMASK_P)) << BSHIFT_EAST   # 0x00ff_0000
const BMASK_NORTH = Cell(Partition(BMASK_P)) << BSHIFT_NORTH  # 0xff00_0000

const QWEST_IDX  = 2  # 3x3 SubArray indices
const QSOUTH_IDX = 6  # [1][4][7]  [  ][qn][  ]
const QEAST_IDX  = 8  # [2][5][8]  [qw][tg][qe]
const QNORTH_IDX = 4  # [3][6][9]  [  ][qs][  ]
const TARGET_IDX = 5  #

include("rule.jl")
include("cellspace.jl")
include("common.jl")

end # module
