# The following bytes have significant meaning in JSON
import Base.Char
Char(arr::Array) = map(Char, arr)
Char(ur::UnitRange{UInt8}) = [Char(i) for i in ur]

const SPACE          = UInt8(' ')
const TAB            = UInt8('\t')
const NEWLINE        = UInt8('\n')
const RETURN         = UInt8('\r')
const FORM_FEED      = UInt8('\f')
const BACKSPACE      = UInt8('\b')
const WS = [TAB, NEWLINE, RETURN]

const STRING_DELIM   = UInt8('"')
const ARRAY_BEGIN    = UInt8('[')
const BACKSLASH      = UInt8('\\')
const ARRAY_END      = UInt8(']')
const OBJECT_BEGIN   = UInt8('{')
const OBJECT_END     = UInt8('}')
const LATIN_T        = UInt8('t')
const LATIN_N        = UInt8('n')
const LATIN_E        = UInt8('e')
const LATIN_U        = UInt8('u')
const LATIN_R        = UInt8('r')
const LATIN_B        = UInt8('b')
const LATIN_F        = UInt8('f')
const LATIN_UPPER_A  = UInt8('A')
const LATIN_UPPER_E  = UInt8('E')
const LATIN_UPPER_F  = UInt8('F')
const DECIMAL_POINT  = UInt8('.')
const LATIN_UPPER_I  = UInt8('I')
const MINUS_SIGN     = UInt8('-')
const PLUS_SIGN      = UInt8('+')
const DIGIT_ZERO     = UInt8('0')
const DIGIT_NINE     = UInt8('9')
const SOLIDUS        = UInt8('/')
const SYN = [ARRAY_BEGIN, ARRAY_END, OBJECT_BEGIN, OBJECT_END]

const SAFE = foldl(vcat, map([0x21,0x23:0x5a, 0x5e:0x7a, 0x7c, 0x7e]) do i
                       if typeof(i) <: UnitRange
                           [ii for ii in i]
                       else
                           [i]
                       end
                   end
                   )


const ANY = vcat(SAFE, WS, SYN, BACKSLASH)

const ESCAPES = Dict(
    STRING_DELIM => STRING_DELIM,
    BACKSLASH    => BACKSLASH,
    LATIN_N      => NEWLINE,
    LATIN_T      => TAB,
    LATIN_R      => RETURN,
    LATIN_F      => FORM_FEED,
    LATIN_B      => BACKSPACE,
    ARRAY_BEGIN  => ARRAY_BEGIN,
    ARRAY_END    => ARRAY_END,
    OBJECT_BEGIN => OBJECT_BEGIN,
    OBJECT_END   => OBJECT_END,
    SOLIDUS      => SOLIDUS
)

const REVERSE_ESCAPES = Dict(reverse(p) for p in ESCAPES)
const ESCAPED_ARRAY = Vector{Vector{UInt8}}(undef, 256)
for c in 0x00:0xFF
    ESCAPED_ARRAY[c + 1] = if c == SOLIDUS
        [SOLIDUS]  # don't escape this one
    elseif c ≥ 0x80
        [c]  # UTF-8 character copied verbatim
    elseif haskey(REVERSE_ESCAPES, c)
        [BACKSLASH, REVERSE_ESCAPES[c]]
    elseif iscntrl(Char(c)) || !isprint(Char(c))
        UInt8[BACKSLASH, LATIN_U, string(c, base=16, pad=4)...]
    else
        [c]
    end
end
export SAFE, WS, ANY, SYN, ARRAY_BEGIN, ARRAY_END, OBJECT_BEGIN, OBJECT_END, STRING_DELIM,
    TAB, NEWLINE, RETURN, ESCAPES, REVERSE_ESCAPES, ESCAPED_ARRAY, SPACE, BACKSLASH,
    LATIN_T, LATIN_N, LATIN_U, DECIMAL_POINT, MINUS_SIGN, LATIN_E, LATIN_UPPER_E, LATIN_UPPER_I,
    PLUS_SIGN, DIGIT_ZERO, DIGIT_NINE, LATIN_UPPER_A, LATIN_UPPER_F
