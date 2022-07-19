using JAMS, JSON, PrettyPrinting

pass_names = begin
    f = readdir("test/pass")
    map(f) do ff
        split(ff, ".")[1]
    end |> union
end

test(n=1) = begin
    for p in pass_names
        @show p
        jam_file = open("test/pass/"*p*".jams") do f
            f |> read |> String
        end
        json_file = open("test/pass/"*p*".json") do f
            f |> read |> String
        end
        try
            jam = JAMS.parse(jam_file)
            println("JAMS:")
            pprintln(jam)
            println("")
            println("*******************")
            println("")
        catch E
            @show E
        end
        try
            json = JSON.parse(json_file)
            println("JSON:")
            pprintln(json)
        catch E
            @warn E
        end
        println()
        try
            jam = JAMS.parse(jam_file)
            json = JSON.parse(json_file)

            @assert jam == json
            pprintln("Hey it worked perfectly!")
        catch E
            @warn E
            @warn "These don't match exactly"
        end

        println("---------------------------------")
        for i=1:5
            println()
        end
        sleep(n)
    end
end
