
type Rule
    dict::Dict{Uint32, (Uint32,Uint32)} # rule dictionary (fin=>(fout,rule_index))
    states::Array{Uint8}                # states of partition
    N::Integer                          # num of transition rules
    Nrot::Integer                       # num of transition rules including rotational symmetry
    function Rule()
        new(Dict{Uint32,Uint32}(),(Uint8)[])
    end
end

function show(rule::Rule)
    println("num of rules            : ", rule.N)
    println("num of rules (inc. rot.): ", rule.Nrot)
end

function save(fname::String, rule::Rule)
    open(fname, "w") do f
        for i in rule.dict
            write(string(hex(i[1],8)," ",hex(i[2],8),"\n"))
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
        # eliminate ret code
        line = replace(line, "\n", "")
        line = replace(line, "\r", "")
        str = split(line[1:end], ' ')
        try
            fin = uint32(string("0x", str[1]))
            fout = uint32(string("0x", str[2]))
            rule_idx += 1
            push!(rule.dict, fin, (fout, rule_idx))
        catch
            continue
        end
    end
    gen_rule_dict(rule)
    add_rotsym_rule(rule.dict)
    rule.N = rule_idx
    rule.Nrot = length(rule.dict)

    rule
end

function gen_rule_dict(rule::Rule)
    states = Dict{Uint8,Uint8}()
    for fin in keys(rule.dict)
        fout,ridx = rule.dict[fin]
        v = (uint64(fin)<<32)|fout
        for i=0:4:60
            elem = uint8((v>>i)&0xf)
            push!(states, elem, elem) 
        end
    end
    keylist = keys(states)
    for key in keylist
        push!(rule.states, key)
    end
end

# 0x1234_5678 -> 0x4123_8567
function rotate(val::Uint32)
    hv = uint16(val>>16)
    lv = uint16(val)
    hv = rotate(hv)
    lv = rotate(lv)
    (uint32(hv)<<16)|uint32(lv)
end

# 0x1234 -> 0x4123
function rotate(val::Uint16)
    (val>>4)|((val&0x000f)<<12)
end

function add_rotsym_rule(dict)
    rot_rules = (Uint32,(Uint32,Uint32))[]
    for fin in keys(dict)
        fout, ridx = dict[fin]

        for i=1:3
            fin = rotate(fin)
            fout = rotate(fout)
            push!(rot_rules, (fin, (fout, ridx)) )
        end
    end
    
    # add rotation symmetry rule to rule dict
    for rule in rot_rules
        push!(dict, rule[1], rule[2])
    end
end

