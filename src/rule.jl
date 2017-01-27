
type Rule
    dict::Dict{Transition, Tuple{Transition,Index}} # rule dictionary (fin=>(fout,rule_index))
    states::Array{Tuple{Partition,Count}}   # states of partition
    N::Count                                # num of transition rules
    Nrot::Count                             # num of transition rules including rotational symmetry
    function Rule()
        dict = Dict{Transition,Tuple{Transition,Index}}()
        states = Tuple{Partition,Count}[]
        new(dict,states,0,0)
    end
end

function save(fname::AbstractString, rule::Rule)
    open(fname, "w") do f
        show(f, rule)
    end
end

function load_rule(fname::AbstractString)
    flines = open(fname) do f
        readlines(f) 
    end
    lines = AbstractString[]
    for line in flines
        # eliminate ret code
        line = chomp(line)

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
        if !ismatch(r"^[0-9a-zA-Z]{8,8}\s[0-9a-zA-Z]{8,8}$", line)
            warn(string("Parse error: ", line))
            continue
        end
        str = split(line[1:end], ' ')
        fin = toval64(str[1])
        fout = toval64(str[2])
        add_rule!(rule, fin, fout)
    end
    gen_partition_states_list!(rule)

    return rule
end

function get_partition_states_list(rule::Rule)
    return map(x->x[1], rule.states)
end

function add_rule!(rule::Rule, fin::Transition, fout::Transition)
   rot_rules = gen_rotational_rule(fin, fout) 
   check_rule_validity(rot_rules)
   has_rotational_rule(rule.dict, rot_rules)
   for r in rot_rules
       # push!(rule.dict, r[1], (r[2], rule.N))
       setindex!(rule.dict, (r[2], rule.N), r[1])
       rule.Nrot+=1
   end
   rule.N+=1
end

function gen_rotational_rule(fin::Transition, fout::Transition)
    rot_rules = Tuple{Transition,Transition}[]
    push!(rot_rules, (fin,fout))
    for i=1:3
        fin = rotate(fin)
        fout = rotate(fout)
        push!(rot_rules, (fin,fout))
    end
    unique(rot_rules)
end

function check_rule_validity(rot_rules::Array{Tuple{Transition,Transition}})
    fins = unique(map(x->x[1],rot_rules))
    fouts = unique(map(x->x[2],rot_rules))
    if length(fins)<length(fouts)
        warn(string("Bad rule: ",tostr(fins[1]),"->", tostr(fouts[1])))
    end
end

function has_rotational_rule(dict::Dict, rot_rules::Array{Tuple{Transition,Transition}})
    for rule in rot_rules
        if haskey(dict,rule[1])
            warn(string("Repeated rule: ",tostr(rule[1]),"->",tostr(rule[2])))
        end
    end
end

function gen_partition_states_list!(rule::Rule)
    states = Dict{Partition,Count}()
    for fin in keys(rule.dict)
        fout,ridx = rule.dict[fin]
        v = (UInt128(fin) << NBITS_T)|fout
        for p in reinterpret(Partition, UInt128[v])
            if haskey(states, p)
                states[p] += 1
            else
                setindex!(states, 1, p) 
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
@inline function rotate(val::Transition)
    hv = Cell(val >> BSHIFT_CELL)
    lv = Cell(val & BMASK_C)
    hv = rotate(hv)
    lv = rotate(lv)
    (Transition(hv) << BSHIFT_CELL)|Transition(lv)
end

# 0x11223344 -> 0x44112233
@inline function rotate(val::Cell)
    (val >> NBITS_P)|((val & BMASK_P) << NBITS_P*3)
end

function show(io::IO, rule::Rule, rotflag::Bool=false)
    if rotflag
        for fin in keys(rule.dict)
            write(io, string(tostr(fin)," ",tostr(rule.dict[fin][1]),"\n"))
        end
    else
        ruleidx = Transition[]
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

