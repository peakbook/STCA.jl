## STCA.jl

[![Build Status](https://travis-ci.org/peakbook/STCA.jl.svg?branch=master)](https://travis-ci.org/peakbook/STCA.jl)  

STCA.jl is a Julia package that provides simple routines for Self-Timed Cellular Automata (STCA) simulations.


### Example

```julia
using STCA

cs = load("cell.txt", :CellSpace)
rule = load("rule.txt", :Rule)

println(rule)

for i=1:10
    update!(cs, rule, :Checkerboard)
    # update!(cs, rule, :Random)
    # update!(cs, rule, x, y)
    println(cs)
end
```


#### rule.txt

```txt
11110101 11111010
```


#### cell.txt

```txt
0000 0000 0000 0000 0000 
0000 0000 0000 0000 0000 
0000 0100 1111 0001 0000 
0000 0000 0000 0000 0000 
0000 0000 0000 0000 0000 
```


### Document

To be written.


