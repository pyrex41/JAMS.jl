using JAMS, JSON
using Test

pass_names = begin
    f = readdir("pass")
    map(f) do ff
        split(ff, ".")[1]
    end |> union
end

@testset "JAMS.jl" begin
    # Write your tests here.
    for p in pass_names
        jam = open("pass/"*p*".jams") do f
            f |> read |> String |> JAMS.parse
        end
        json = open("pass/"*p*".json") do f
            f |> read |> String |> JSON.parse
        end
        @test jam == json
    end
end
