# JAMS

Currently built just by defining the Grammar and using `Lerche.jl` to build a parser.

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

1 test still failing, need to sort out how to handle escape charachters inside quotes (test 9, "quotes-never-fail").

<img width="751" alt="Screen Shot 2022-07-19 at 12 24 12 PM" src="https://user-images.githubusercontent.com/12162406/179832064-c7cd2b52-46c4-45fb-8c0a-06a141b09ee5.png">

A lot of performance improvements available
<img width="266" alt="Screen Shot 2022-07-19 at 12 21 21 PM" src="https://user-images.githubusercontent.com/12162406/179831686-71a06f3c-ddc9-45b8-82ab-cb1a9bc2c62b.png">
