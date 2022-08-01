#include("../src/JAMS.jl")
using JAMS, JSON
using Test

pass_names = begin
    f = readdir("pass")
    map(f) do ff
        split(ff, ".")[1]
    end |> union
end

@testset "Pass Tests" begin
    # Write your tests here.
    for p in pass_names
        jam = "pass/"*p*".jams" |> JAMS.parsefile
        json = "pass/"*p*".json" |> JSON.parsefile
        @test jam == json
    end
end

fail_names = begin
    f = readdir("fail")
    map(f) do ff
        "fail/"*ff
    end
end

@testset "Fail Tests" begin
    # Write your tests here.
    for f in fail_names
        jam = @test_throws ErrorException begin
            f |> JAMS.parsefile
        end
    end

end
