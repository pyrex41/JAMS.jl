using .JAMS, JSON
using Test

pass_names = begin
    f = readdir("test/pass")
    map(f) do ff
        split(ff, ".")[1]
    end |> union
end

@testset "Pass Tests" begin
    # Write your tests here.
    for p in pass_names
        jam = "test/pass/"*p*".jams" |> JAMS.parsefile
        json = "test/pass/"*p*".json" |> JSON.parsefile
        @test jam == json
    end
end

fail_names = begin
    f = readdir("test/fail")
    map(f) do ff
        "test/fail/"*ff
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
