module JAMS

include("Common.jl")
include("Parser.jl")

using .Parser: parse, parsefile

export parse, parsefile

end # end module
