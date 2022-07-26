include("../src/JAMS.jl")
using .JAMS, JSON, BenchmarkTools


pass_names = begin
    f = readdir("test/pass")
    map(f) do ff
        split(ff, ".")[1]
    end |> union
end

function jamrun(p)
    s = read("test/pass/"*p*".jams") |> String
    @btime JAMS.parse($s)
end

function jsonrun(p)
    s = read("test/pass/"*p*".json") |> String
    @btime JSON.parse($s)
end

function bench(ii)
    i = max(min(length(pass_names), ii), 1)
    p = pass_names[i]
    println("Test: ", p)
    print("JAMS:   ")
    jamrun(p)
    println("-----")
    print("JSON:   ")
    jsonrun(p)
    println("-----------------------------")
end

function benchall()
    for i=1:length(pass_names)
        bench(i)
        println()
        sleep(1)
    end
end
