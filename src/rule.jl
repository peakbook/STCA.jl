
type Rule
    # rule dictionary
    list::Dict{Uint32, Uint32} 
    function Rule()
        new(Dict{Uint32,Uint32}())
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
            str = split(line[1:end-1], ' ')
            a = int32(string("0x",str[1]))
            b = int32(string("0x",str[2]))
            push!(rule.list, a,b)
        end
    end
    # add rotate rules
    add_rotate_rule(rule.list)
    rule
end

function rotate(val::Uint32)
    hv = uint16(val>>16)
    lv = uint16(val)
    hv = rotate(hv)
    lv = rotate(lv)
    uint32(hv)<<16|uint32(lv)
end

function rotate(val::Uint16)
    (val>>4)|((val&0x000f)<<12)
end

function add_rotate_rule(list)
    for vin in keys(list)
        vout = list[vin]

        # rotate 1
        vin_r1 = rotate(vin)
        vout_r1 = rotate(vout)
        push!(list, vin_r1, vout_r1) 

        # rotate 2
        vin_r2 = rotate(vin_r1)
        vout_r2 = rotate(vout_r1)
        push!(list, vin_r2, vout_r2) 

        # rotate 3
        vin_r3 = rotate(vin_r2)
        vout_r3 = rotate(vout_r2)
        push!(list, vin_r3, vout_r3) 
    end
end

