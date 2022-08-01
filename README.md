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

(JAMS) pkg> test
     Testing JAMS
      Status `/private/var/folders/nh/ncg8xhd91h925n5nzgysjs6c0000gn/T/jl_qkAsPc/Project.toml`
  [e037fcc2] JAMS v0.1.0 `~/.julia/dev/JAMS`
  [682c06a0] JSON v0.21.3
  [69de0a69] Parsers v2.3.2
  [a63ad114] Mmap `@stdlib/Mmap`
  [8dfed614] Test `@stdlib/Test`
  [4ec0a83e] Unicode `@stdlib/Unicode`
      Status `/private/var/folders/nh/ncg8xhd91h925n5nzgysjs6c0000gn/T/jl_qkAsPc/Manifest.toml`
  [e037fcc2] JAMS v0.1.0 `~/.julia/dev/JAMS`
  [682c06a0] JSON v0.21.3
  [69de0a69] Parsers v2.3.2
  [2a0f44e3] Base64 `@stdlib/Base64`
  [ade2ca70] Dates `@stdlib/Dates`
  [b77e0a4c] InteractiveUtils `@stdlib/InteractiveUtils`
  [56ddb016] Logging `@stdlib/Logging`
  [d6f4376e] Markdown `@stdlib/Markdown`
  [a63ad114] Mmap `@stdlib/Mmap`
  [de0858da] Printf `@stdlib/Printf`
  [9a3f8284] Random `@stdlib/Random`
  [ea8e919c] SHA `@stdlib/SHA`
  [9e88b42a] Serialization `@stdlib/Serialization`
  [8dfed614] Test `@stdlib/Test`
  [4ec0a83e] Unicode `@stdlib/Unicode`
     Testing Running tests...
Test Summary: | Pass  Total
Pass Tests    |   12     12
Test Summary: | Pass  Total
Fail Tests    |    9      9
     Testing JAMS tests passed
```
