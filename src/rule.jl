
type Rule
    dict::Dict{Uint64, (Uint64,Uint64)} # rule dictionary (fin=>(fout,rule_index))
    states::Array{Uint8}                # states of partition
    N::Integer                          # num of transition rules
    Nrot::Integer                       # num of transition rules including rotational symmetry
    function Rule()
        new(Dict{Uint64,(Uint64,Uint64)}(),(Uint8)[])
    end
end

function show(rule::Rule)
    println("num of rules            : ", rule.N)
    println("num of rules (inc. rot.): ", rule.Nrot)
end

function save(fname::String, rule::Rule)
    open(fname, "w") do f
        for i in rule.dict
            write(string(tostr(i[1])," ",tostr(i[2]),"\n"))
        end
    end
end

function load_rule(fname::String)
    rule = Rule()
    lines = nothing
    open(fname) do f
       lines = readlines(f) 
    end

    rule_idx = 0
    for line in lines
        # skip comment line
        if ismatch(r"^\s*(#)",line)
            continue
        end

        # eliminate ret code
        line = replace(line, "\n", "")
        line = replace(line, "\r", "")
        str = split(line[1:end], ' ')
        try
            fin = toval64(str[1])
            fout = toval64(str[2])
            if has_rotational_rule(rule.dict, fin)
                throw(tostr(fin)) # include rotational symmetry rule
            end
            rule_idx += 1
            push!(rule.dict, fin, (fout, rule_idx))
        catch ex
            continue
        end
    end
    gen_partition_states_list(rule)
    add_rotsym_rule(rule.dict)
    rule.N = rule_idx
    rule.Nrot = length(rule.dict)

    rule
end

function has_rotational_rule(dict::Dict, val::Uint64)
    r1 = rotate(val)
    r2 = rotate(r1)
    r3 = rotate(r2)
    haskey(dict,val)||haskey(dict, r1)||haskey(dict, r2)||haskey(dict, r3)
end

function gen_partition_states_list(rule::Rule)
    states = Dict{Uint8,Uint8}()
    for fin in keys(rule.dict)
        fout,ridx = rule.dict[fin]
        v = (uint128(fin)<<64)|fout
        for i=0:8:120
            elem = uint8((v>>i)&0xff)
            push!(states, elem, elem) 
        end
    end
    keylist = keys(states)
    for key in keylist
        push!(rule.states, key)
    end
end

# 0x11223344_55667788 -> 0x44112233_88556677
function rotate(val::Uint64)
    hv = uint32(val>>32)
    lv = uint32(val)
    hv = rotate(hv)
    lv = rotate(lv)
    (uint64(hv)<<32)|uint64(lv)
end

# 0x11223344 -> 0x44112233
function rotate(val::Uint32)
    (val>>8)|((val&0x0000_000ff)<<24)
end

function add_rotsym_rule(dict)
    rot_rules = (Uint64,(Uint64,Uint64))[]
    for fin in keys(dict)
        fout, ridx = dict[fin]

        tfin = fin
        tfout = fout
        for i=1:3
            tfin = rotate(tfin)
            tfout = rotate(tfout)
            if tfin != fin
                push!(rot_rules, (tfin, (tfout, ridx) ))
            end
        end
    end
    rot_rules = unique(rot_rules)
    
    # add rotation symmetry rule to rule dict
    for rule in rot_rules
        @assert(!haskey(dict, rule[1]), string("bad rule: ", tostr(rule[1]),"->",tostr(rule[2][1])))
        push!(dict, rule[1], rule[2])
    end
end

