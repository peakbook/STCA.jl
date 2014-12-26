
type Rule
    # rule dictionary
    list::Dict{Uint32, Uint32} 
    states::Array{Uint8}
    function Rule()
        new(Dict{Uint32,Uint32}(),(Uint8)[])
    end
end

function save(fname::String, rule::Rule)
    open(fname, "w") do f
        for i in rule.list
            write(string(hex(i[1],8)," ",hex(i[2],8),"\n"))
        end
    end
end

function load_rule(fname::String)
    rule = Rule()
    open(fname) do f
        while true
            line = readline(f)
            if length(line)<=1
                break
            end
            str = split(line[1:end], ' ')
            if str[end]=="\n"
                str=str[1:end-1]
            end
            a = uint32(string("0x",str[1]))
            b = uint32(string("0x",str[2]))
            push!(rule.list, a,b)
        end
    end
    gen_states_list(rule)
    add_rotate_rule(rule.list)
    rule
end

function gen_states_list(rule::Rule)
    states = Dict{Uint8,Uint8}()
    for vin in keys(rule.list)
        vout = rule.list[vin]
        v = (uint64(vin)<<32)|vout
        for i=0:4:60
            elem = uint8((v>>i)&0xf)
            push!(states, elem,elem) 
        end
    end
    keylist = keys(states)
    for key in keylist
        push!(rule.states, key)
    end
end

function rotate(val::Uint32)
    hv = uint16(val>>16)
    lv = uint16(val)
    hv = rotate(hv)
    lv = rotate(lv)
    (uint32(hv)<<16)|uint32(lv)
end

function rotate(val::Uint16)
    (val>>4)|((val&0x000f)<<12)
end

function add_rotate_rule(list)
    rot_rules = (Uint32,Uint32)[]
    for vin in keys(list)
        vout = list[vin]

        for i=1:3
            vin = rotate(vin)
            vout = rotate(vout)
            push!(rot_rules, (vin, vout) )
        end
    end
    for rule in rot_rules
        push!(list, rule[1], rule[2])
    end
end

