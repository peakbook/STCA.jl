
type Rule
    dict::Dict{Uint64, (Uint64,Uint64)} # rule dictionary (fin=>(fout,rule_index))
    states::Array{(Uint8,Uint)}         # states of partition
    N::Uint64                           # num of transition rules
    Nrot::Uint64                        # num of transition rules including rotational symmetry
    function Rule()
        new(Dict{Uint64,(Uint64,Uint64)}(),(Uint8)[],0,0)
    end
end

function save(fname::String, rule::Rule)
    open(fname, "w") do f
        show(f, rule)
    end
end

function load_rule(fname::String)
    flines = open(fname) do f
        readlines(f) 
    end
    lines = String[]
    for line in flines
        # eliminate ret code
        line = replace(line, r"\s*(\r|\n)", "")

        # skip comment/brank line
        if ismatch(r"^\s*(#)",line) || length(line)==0
            continue
        end

        push!(lines, line)
    end

    load_rule(lines)
end 

function load_rule(lines::Array)
    rule = Rule()

    for line in lines
        str = split(line[1:end], ' ')
        try
            fin = toval64(str[1])
            fout = toval64(str[2])
            add_rule(rule, fin, fout)
        catch ex
            println(ex)
            continue
        end
    end
    gen_partition_states_list(rule)

    rule
end

function add_rule(rule::Rule, fin::Uint64, fout::Uint64)
   rot_rules = gen_rotational_rule(fin, fout) 
   check_rule_validity(rot_rules)
   has_rotational_rule(rule.dict, rot_rules)
   for r in rot_rules
       push!(rule.dict, r[1], (r[2], rule.N))
       rule.Nrot+=1
   end
   rule.N+=1
end

function gen_rotational_rule(fin::Uint64, fout::Uint64)
    rot_rules = (Uint64,Uint64)[]
    push!(rot_rules, (fin,fout))
    for i=1:3
        fin = rotate(fin)
        fout = rotate(fout)
        push!(rot_rules, (fin,fout))
    end
    unique(rot_rules)
end

function check_rule_validity(rot_rules::Array{(Uint,Uint)})
    fins = unique(map(x->x[1],rot_rules))
    fouts = unique(map(x->x[2],rot_rules))
    if length(fins)<length(fouts)
        throw(string("*caution* bad rule: ",tostr(fins[1]),"->", tostr(fouts[1])))
    end
end

function has_rotational_rule(dict::Dict, rot_rules::Array{(Uint,Uint)})
    for rule in rot_rules
        if haskey(dict,rule[1])
            throw(string("*caution* dup rule: ",tostr(rule[1]),"->",tostr(rule[2])))
        end
    end
end

function gen_partition_states_list(rule::Rule)
    states = Dict{Uint8,Uint}()
    for fin in keys(rule.dict)
        fout,ridx = rule.dict[fin]
        v = (uint128(fin)<<64)|fout
        for i=0:8:120
            p = uint8((v>>i)&0xff)
            if haskey(states, p)
                states[p] += 1
            else
                push!(states, p, 1) 
            end
        end
    end
    keylist = keys(states)
    for key in keylist
        push!(rule.states, (key, states[key]))
    end
    sort!(rule.states, by=x->x[2])
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

function show(io::IO, rule::Rule, rotflag::Bool=false)
    if rotflag
        for fin in keys(rule.dict)
            write(io, string(tostr(fin)," ",tostr(rule.dict[fin][1]),"\n"))
        end
    else
        ruleidx = Uint64[]
        for fin in keys(rule.dict)
            if !(rule.dict[fin][2] in ruleidx)
                write(io, string(tostr(fin)," ",tostr(rule.dict[fin][1]),"\n"))
                push!(ruleidx, rule.dict[fin][2])
            end
        end
    end
end

function print(rule::Rule, rotflag::Bool=false)
    show(STDOUT, rule, fotflag)
end

function println(rule::Rule, rotflag::Bool=false)
    show(STDOUT, rule, rotflag)
    println()
end

