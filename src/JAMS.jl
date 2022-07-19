module JAMS

using Lerche, JSON

jams_grammar = raw"""
     ?start: jam
     ?jam   : obj
            | arr
            | str
     obj    : "{" duo* "}"
     arr    : "[" jam* "]"
     duo    : str jam
     str    : STRING
     ESTRING: /"(?:[^"\\]|\\.|\\\\)*"/
     STRING : SAFE+ | ESTRING
     WS     : /[ \t\n\r]/+
     %ignore WS
     SYN    : "{"
            | "}"
            | "["
            | "]"
     CHAR   : "!" | ":" | ";" | "<" | "=" | ">" | "$" | "?" | "@" | "#" | "%" | "&" | "'" | "(" | ")" | "*" | "+" | "," | "-" | "." | "/" | "^" | "_" | "|" | "~" | "`"
     %import common.LETTER
     %import common.DIGIT
     SAFE   : LETTER | DIGIT | CHAR
"""

struct TreeToJams <: Transformer end
@inline_rule str(t::TreeToJams, ss) = begin
    s = replace(ss, "\\\""=>"\"")
    s[1] == '"' && s[end] == '"' ? s[2:end-1] : s
end

#@rule str(t::TreeToJams, s) = string(s)
@rule arr(t::TreeToJams, a) = Array(a)
@rule duo(t::TreeToJams, d) = Tuple(d)
@rule obj(t::TreeToJams, o) = Dict(o)

jams_parser = Lark(jams_grammar, parser="lalr", lexer="contextual", transformer = TreeToJams())

parse(file, args...; kwargs...) = Lerche.parse(jams_parser, file, args...; kwargs...)

end # end module
