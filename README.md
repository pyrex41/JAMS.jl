# JAMS

Built by refactoring [JSON.jl](https://github.com/JuliaIO/JSON.jl).

Exports `parse` and `parsefile`


```julia
julia> using JAMS

julia> f = read("test/pass/nested_example.jams") |> String
"{\n    basic_key basic_value\n    list_key [item1 item2]\n    nested [\n        {\n            key1 val1 \n            key2 val2\n        }\n        {\n            key3 [val3 val4]\n        }\n    ]\n    str_key \"superfluous nesting\"\n}\n"

julia> JAMS.parse(f)
Dict{String, Any} with 4 entries:
  "list_key"  => Any["item1", "item2"]
  "basic_key" => "basic_value"
  "str_key"   => "superfluous nesting"
  "nested"    => Any[Dict("key2"=>"val2", "key1"=>"val1"), Dict{String, …
```

To run tests:

``` julia
╰─ julia --project
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.7.2 (2022-02-06)
 _/ |\__'_|_|_|\__'_|  |  HEAD/bf53498635 (fork: 461 commits, 418 days)
|__/                   |

julia> using JAMS
[ Info: Precompiling JAMS [e037fcc2-89bb-496d-a467-a0483cd5c74c]

julia> include("test/runtests.jl")
Test Summary: | Pass  Total
Pass Tests    |   12     12
Test Summary: | Pass  Total
Fail Tests    |    9      9
Test.DefaultTestSet("Fail Tests", Any[], 9, false, false)
```
