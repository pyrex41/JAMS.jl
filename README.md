# JAMS

Implementing https://nikolai.fyi/jams/

Built by refactoring [JSON.jl](https://github.com/JuliaIO/JSON.jl).

Currently only implementing parsing; encoding is a separate straightforward extension.

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

To run benchmarks:
```julia
╰─ julia --project
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.7.2 (2022-02-06)
 _/ |\__'_|_|_|\__'_|  |  HEAD/bf53498635 (fork: 461 commits, 418 days)
|__/                   |

julia> include("benchmark/benchmark.jl")
benchall (generic function with 1 method)

julia> benchall()
Test: bare1
JAMS:     1.046 μs (21 allocations: 1.19 KiB)
-----
JSON:     334.649 ns (9 allocations: 672 bytes)
-----------------------------

Test: bare2
JAMS:     847.217 ns (21 allocations: 1.19 KiB)
-----
JSON:     318.551 ns (9 allocations: 672 bytes)
-----------------------------

Test: bareAll
JAMS:     1.071 μs (21 allocations: 1.19 KiB)
-----
JSON:     337.118 ns (9 allocations: 688 bytes)
-----------------------------

Test: double-quote
JAMS:     210.135 ns (5 allocations: 288 bytes)
-----
JSON:     237.430 ns (7 allocations: 320 bytes)
-----------------------------

Test: emptyquotes
JAMS:     673.116 ns (17 allocations: 1.11 KiB)
-----
JSON:     312.586 ns (8 allocations: 640 bytes)
-----------------------------

Test: example
JAMS:     5.604 μs (103 allocations: 5.02 KiB)
-----
JSON:     1.038 μs (35 allocations: 1.92 KiB)
-----------------------------

Test: nested_example
JAMS:     7.292 μs (135 allocations: 6.75 KiB)
-----
JSON:     1.417 μs (49 allocations: 2.86 KiB)
-----------------------------

Test: one-empty-quote
JAMS:     195.819 ns (5 allocations: 288 bytes)
-----
JSON:     176.717 ns (2 allocations: 64 bytes)
-----------------------------

Test: quotes-never-fail
JAMS:     5.327 μs (114 allocations: 5.92 KiB)
-----
JSON:     1.783 μs (77 allocations: 3.69 KiB)
-----------------------------

Test: str
JAMS:     306.510 ns (9 allocations: 368 bytes)
-----
JSON:     182.055 ns (3 allocations: 96 bytes)
-----------------------------

Test: trailing-whitespaces
JAMS:     218.296 ns (5 allocations: 288 bytes)
-----
JSON:     189.950 ns (3 allocations: 96 bytes)
-----------------------------

Test: wethpack
JAMS:     17.333 μs (208 allocations: 11.31 KiB)
-----
JSON:     2.153 μs (73 allocations: 5.03 KiB)
-----------------------------
```
