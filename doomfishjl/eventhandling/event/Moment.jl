


struct Moment
    value::Union{ Int, String }
    Moment(;value) = new(value)
end

# we explicitly use Base.tryparse b/c Parsers.tryparse has different behavior.
# Seriously Julia?
Moment( val::String ) = Base.tryparse(Int, val) != nothing ? Moment( value=parse(Int, val) ) : Moment(value=val)
Moment( val::Int ) = Moment( value=val )

# pointless? maybe.
macro moment_str( value )
    Base.tryparse(Int, value) != nothing ? Moment( parse(Int, value) ) : Moment(value)
end
