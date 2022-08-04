module Parser  # JAMS
using ..Common, Mmap
import Parsers
import Base.isdigit

"""
Like `isspace`, but work on bytes and includes only the four whitespace
characters defined by the JSON standard: space, tab, line feed, and carriage
return.
"""
isjamspace(b::UInt8) = b == SPACE || b == TAB || b == NEWLINE

"""
Check if a number before converting
"""
isdigit(b::UInt8) = UInt8('0') ≤ b ≤ UInt8('9')
isnumber_component(b::UInt8) = isdigit(b) || b == MINUS_SIGN || b == DECIMAL_POINT
isnumber_component(c::Char) = isnumber_component(UInt8(c))
isdecimalpoint(b::UInt8) = b == DECIMAL_POINT
isdecimalpoint(c::Char) = isdecimalpoint(UInt8(c))
isminussign(b::UInt8) = b == MINUS_SIGN
isminussign(c::Char) = isminussign(UInt8(c))

function isnumber(s::Union{AbstractString, Vector{UInt8}, Vector{Char}})
    dotcount = 0
    minuscount = 0
    out = true
    foreach(s) do c
        if !isnumber_component(c)
            out = false
        end
        if isdecimalpoint(c)
            dotcount += 1
        end
        if isminussign(c)
            minuscount += 1
        end
    end
    out = out && dotcount <= 1 && minuscount <= 1
    out = minuscount == 0 ? out : (out && isminussign(first(s)))
    t = dotcount == 0 ? Int64 : Float64
    out, t
end

"""
Only convert strings that are actually numbers to numbers
"""
function safe_convert(s::Union{AbstractString, Vector{UInt8}, Vector{Char}})
    bool, type_ = isnumber(s)
    bool ? Base.parse(type_, s) : s
end

abstract type ParserState end

mutable struct MemoryParserState <: ParserState
    utf8::String
    s::Int
end

# it is convenient to access MemoryParserState like a Vector{UInt8} to avoid copies
Base.@propagate_inbounds Base.getindex(state::MemoryParserState, i::Int) = codeunit(state.utf8, i)
Base.length(state::MemoryParserState) = sizeof(state.utf8)

mutable struct StreamingParserState{T <: IO} <: ParserState
    io::T
    cur::UInt8
    used::Bool
    utf8array::Vector{UInt8}
end
StreamingParserState(io::IO) = StreamingParserState(io, 0x00, true, UInt8[])

struct ParserContext{DictType, IntType, AllowNanInf, NullValue} end

"""
Return the byte at the current position of the `ParserState`. If there is no
byte (that is, the `ParserState` is done), then an error is thrown that the
input ended unexpectedly.
"""
@inline function byteat(ps::MemoryParserState)
    @inbounds if hasmore(ps)
        return ps[ps.s]
    else
        _error(E_UNEXPECTED_EOF, ps)
    end
end

@inline function byteat(ps::StreamingParserState)
    if ps.used
        ps.used = false
        if eof(ps.io)
            _error(E_UNEXPECTED_EOF, ps)
        else
            ps.cur = read(ps.io, UInt8)
        end
    end
    ps.cur
end

"""
Like `byteat`, but with no special bounds check and error message. Useful when
a current byte is known to exist.
"""
@inline current(ps::MemoryParserState) = ps[ps.s]
@inline current(ps::StreamingParserState) = byteat(ps)

"""
Require the current byte of the `ParserState` to be the given byte, and then
skip past that byte. Otherwise, an error is thrown.
"""
@inline function skip!(ps::ParserState, c::UInt8)
    if byteat(ps) == c
        incr!(ps)
    else
        _error_expected_char(c, ps)
    end
end
@noinline _error_expected_char(c, ps) = _error("Expected '$(Char(c))' here", ps)

function skip!(ps::ParserState, cs::UInt8...)
    for c in cs
        skip!(ps, c)
    end
end

"""
Move the `ParserState` to the next byte.
"""
@inline incr!(ps::MemoryParserState) = (ps.s += 1)
@inline incr!(ps::StreamingParserState) = (ps.used = true)

"""
Move the `ParserState` to the next byte, and return the value at the byte before
the advancement. If the `ParserState` is already done, then throw an error.
"""
@inline advance!(ps::ParserState) = (b = byteat(ps); incr!(ps); b)

"""
Return `true` if there is a current byte, and `false` if all bytes have been
exausted.
"""
@inline hasmore(ps::MemoryParserState) = ps.s ≤ length(ps)
@inline hasmore(ps::StreamingParserState) = true  # no more now ≠ no more ever

"""
Remove as many whitespace bytes as possible from the `ParserState` starting from
the current byte.
"""
@inline function chomp_space!(ps::ParserState)
    @inbounds while hasmore(ps) && isjamspace(current(ps))
        incr!(ps)
    end
end


# Used for line counts
function _count_before(haystack::AbstractString, needle::Char, _end::Int)
    count = 0
    for (i,c) in enumerate(haystack)
        i >= _end && return count
        count += c == needle
    end
    return count
end


# Throws an error message with an indicator to the source
@noinline function _error(message::AbstractString, ps::MemoryParserState)
    orig = ps.utf8
    lines = _count_before(orig, '\n', ps.s)
    # Replace all special multi-line/multi-space characters with a space.
    strnl = replace(orig, r"[\b\f\n\r\t\s]" => " ")
    li = (ps.s > 20) ? ps.s - 9 : 1 # Left index
    ri = min(lastindex(orig), ps.s + 20)       # Right index
    error(message *
      "\nLine: " * string(lines) *
      "\nAround: ..." * strnl[li:ri] * "..." *
      "\n           " * (" " ^ (ps.s - li)) * "^\n"
    )
end

@noinline function _error(message::AbstractString, ps::StreamingParserState)
    error("$message\n ...when parsing byte with value '$(current(ps))'")
end

# PARSING

"""
Given a `ParserState`, after possibly any amount of whitespace, return the next
parseable value.
"""
function parse_jam(pc::ParserContext, ps::ParserState)
    chomp_space!(ps)

    @inbounds byte = byteat(ps)
    if byte == OBJECT_BEGIN
        parse_object(pc, ps)
    elseif byte == ARRAY_BEGIN
        parse_array(pc, ps)
    else
        parse_str(pc, ps)
    end
end

# method that stips over closing symbol for processing bare words
function parse_jam(pc::ParserContext, ps::ParserState, closing::UInt8)
    chomp_space!(ps)

    @inbounds byte = byteat(ps)
    if byte == OBJECT_BEGIN
        parse_object(pc, ps)
    elseif byte == ARRAY_BEGIN
        parse_array(pc, ps)
    else
        parse_str(pc, ps, closing)
    end
end

BARE_FUNC(x) = x |> String |> safe_convert

function parse_bare(ps::ParserState)
    chomp_space!(ps)
    b = IOBuffer()
    l = length(ps.utf8)
    for _=1:l
        c = advance!(ps)
        if c in SAFE
            write(b, c)
        elseif c == SPACE || c in WS
            return take!(b) |> BARE_FUNC
        else
            _error(E_UNEXPECTED_CHAR, ps)
        end
    end
    take!(b) |> BARE_FUNC
end

# method that skips over specified closing character
function parse_bare(ps::ParserState, closing::UInt8)
    chomp_space!(ps)
    b = IOBuffer()
    l = length(ps.utf8)
    func = String # or Symbol
    for _=1:l
        c = byteat(ps)
        if c in SAFE
            advance!(ps)
            write(b, c)
        elseif c == SPACE || c in WS
            advance!(ps)
            return take!(b) |> BARE_FUNC
        elseif c == closing
            return take!(b) |> BARE_FUNC
        else
            advance!(ps)
            _error(E_UNEXPECTED_CHAR, ps)
        end
    end
    advance!(ps)
    take!(b) |> BARE_FUNC
end

function parse_array(pc::ParserContext, ps::ParserState)
    result = Any[]
    @inbounds incr!(ps)  # Skip over opening '['
    chomp_space!(ps)
    if byteat(ps) ≠ ARRAY_END  # special case for empty array
        @inbounds while true
            push!(result, parse_jam(pc, ps, ARRAY_END))
            chomp_space!(ps)
            byteat(ps) == ARRAY_END && break
        end
    end

    @inbounds incr!(ps)
    result
end



function parse_str(pc::ParserContext, ps::ParserState)
    byte = byteat(ps)
    if byte == STRING_DELIM
        parse_quote(ps)
    #elseif isdigit(byte) || byte == MINUS_SIGN
     #   parse_number(pc, ps)
    else
        parse_bare(ps)
    end
end

# method to skip over optional closing character for bare words
function parse_str(pc::ParserContext, ps::ParserState, closing::UInt8)
    byte = byteat(ps)
    if byte == STRING_DELIM
        parse_quote(ps)
#    elseif isdigit(byte) || byte == MINUS_SIGN
        #parse_number(pc, ps)
    else
        parse_bare(ps, closing)
    end
end

function parse_object(pc::ParserContext{DictType,<:Real,<:Any}, ps::ParserState) where DictType
    obj = DictType()
    keyT = keytype(typeof(obj))

    chomp_space!(ps)
    c = advance!(ps )# Skip over opening '{'
    @assert c == OBJECT_BEGIN
    chomp_space!(ps)
    if byteat(ps) ≠ OBJECT_END  # special case for empty object
        @inbounds while true
            # Read duo
            # Read key
            chomp_space!(ps)
            key = parse_str(pc, ps)
            chomp_space!(ps)
            # Read value
            value = parse_jam(pc, ps, OBJECT_END)
            chomp_space!(ps)
            obj[keyT === Symbol ? Symbol(key) : convert(keyT, key)] = value
            byteat(ps) == OBJECT_END && break
        end
    end
    incr!(ps)
    obj
end


utf16_is_surrogate(c::UInt16) = (c & 0xf800) == 0xd800
utf16_get_supplementary(lead::UInt16, trail::UInt16) = Char(UInt32(lead-0xd7f7)<<10 + trail)

function read_four_hex_digits!(ps::ParserState)
    local n::UInt16 = 0

    for _ in 1:4
        b = advance!(ps)
        n = n << 4 + if isdigit(b)
            b - DIGIT_ZERO
        elseif LATIN_A ≤ b ≤ LATIN_F
            b - (LATIN_A - UInt8(10))
        elseif LATIN_UPPER_A ≤ b ≤ LATIN_UPPER_F
            b - (LATIN_UPPER_A - UInt8(10))
        else
            _error(E_BAD_ESCAPE, ps)
        end
    end

    n
end

function read_unicode_escape!(ps)
    u1 = read_four_hex_digits!(ps)
    if utf16_is_surrogate(u1)
        skip!(ps, BACKSLASH)
        skip!(ps, LATIN_U)
        u2 = read_four_hex_digits!(ps)
        utf16_get_supplementary(u1, u2)
    else
        Char(u1)
    end
end

function parse_quote(ps::ParserState)
    b = IOBuffer()
    incr!(ps)  # skip opening quote
    while true
        c = advance!(ps)

        if c == BACKSLASH
            c = advance!(ps)
            if c == LATIN_U  # Unicode escape
                write(b, read_unicode_escape!(ps))
            else
                c = get(ESCAPES, c, 0x00)
                c == 0x00 && _error(E_BAD_ESCAPE, ps)
                write(b, c)
            end
            continue
        elseif c == STRING_DELIM
            return String(take!(b))
        elseif c ∋ ANY
            _error(E_BAD_CONTROL, ps)
        end
        write(b, c)
    end
end


unparameterize_type(x) = x # Fallback for nontypes -- functions etc
function unparameterize_type(T::Type)
    candidate = typeintersect(T, AbstractDict{String, Any})
    candidate <: Union{} ? T : candidate
end

# Workaround for slow dynamic dispatch for creating objects
const DEFAULT_PARSERCONTEXT = ParserContext{Dict{String, Any}, Int64, false, nothing}()
function _get_parsercontext(dicttype, inttype, allownan, null)
    if dicttype == Dict{String, Any} && inttype == Int64 && !allownan
        DEFAULT_PARSERCONTEXT
    else
        ParserContext{unparameterize_type(dicttype), inttype, allownan, null}.instance
    end
end

"""
    parse(str::AbstractString;
          dicttype::Type{T}=Dict,
          inttype::Type{<:Real}=Int64,
          allownan::Bool=true,
          null=nothing) where {T<:AbstractDict}

Parses the given JSON string into corresponding Julia types.

Keyword arguments:
  • dicttype: Associative type to use when parsing JSON objects (default: Dict{String, Any})
  • inttype: Real number type to use when parsing JSON numbers that can be parsed
             as integers (default: Int64)
  • allownan: allow parsing of NaN, Infinity, and -Infinity (default: true)
  • null: value to use for parsed JSON `null` values (default: `nothing`)
"""
function parse(str::AbstractString;
               dicttype=Dict{String,Any},
               inttype::Type{<:Real}=Int64,
               allownan::Bool=true,
               null=nothing)
    pc = _get_parsercontext(dicttype, inttype, allownan, null)
    ps = MemoryParserState(str, 1)
    v = parse_jam(pc, ps)
    chomp_space!(ps)
    if hasmore(ps)
        _error(E_EXPECTED_EOF, ps)
    end
    v
end

"""
    parse(io::IO;
          dicttype::Type{T}=Dict,
          inttype::Type{<:Real}=Int64,
          allownan=true,
          null=nothing) where {T<:AbstractDict}

Parses JSON from the given IO stream into corresponding Julia types.

Keyword arguments:
  • dicttype: Associative type to use when parsing JSON objects (default: Dict{String, Any})
  • inttype: Real number type to use when parsing JSON numbers that can be parsed
             as integers (default: Int64)
  • allownan: allow parsing of NaN, Infinity, and -Infinity (default: true)
  • null: value to use for parsed JSON `null` values (default: `nothing`)
"""
function parse(io::IO;
               dicttype=Dict{String,Any},
               inttype::Type{<:Real}=Int64,
               allownan::Bool=true,
               null=nothing)
    pc = _get_parsercontext(dicttype, inttype, allownan, null)
    ps = StreamingParserState(io)
    parse_jam(pc, ps)
end

"""
    parsefile(filename::AbstractString;
              dicttype=Dict{String, Any},
              inttype::Type{<:Real}=Int64,
              allownan::Bool=true,
              null=nothing,
              use_mmap::Bool=true)

Convenience function to parse JSON from the given file into corresponding Julia types.

Keyword arguments:
  • dicttype: Associative type to use when parsing JSON objects (default: Dict{String, Any})
  • inttype: Real number type to use when parsing JSON numbers that can be parsed
             as integers (default: Int64)
  • allownan: allow parsing of NaN, Infinity, and -Infinity (default: true)
  • null: value to use for parsed JSON `null` values (default: `nothing`)
  • use_mmap: use mmap when opening the file (default: true)
"""
function parsefile(filename::AbstractString;
                   dicttype=Dict{String, Any},
                   inttype::Type{<:Real}=Int64,
                   null=nothing,
                   allownan::Bool=true,
                   use_mmap::Bool=true)
    sz = filesize(filename)
    open(filename) do io
        s = use_mmap ? String(Mmap.mmap(io, Vector{UInt8}, sz)) : read(io, String)
        parse(s; dicttype=dicttype, inttype=inttype, allownan=allownan, null=null)
    end
end

# Efficient implementations of some of the above for in-memory parsing
#include("specialized.jl")

end  # module Parser
