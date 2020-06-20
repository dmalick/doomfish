import Base.convert


FUNCTION_DEF_PATTERN = r".+\(.*\)"


function checkState(state::Bool, errorMessage::String="invalid state: $state")
    if !state
        error(errorMessage)
    end
end

function checkArgument(conditional::Bool, errorMessage::String="$conditional not met")
    if !conditional
        throw(ArgumentError(errorMessage))
    end
end

checkArgument(arg, f::Function, errorMessage::String="$f(arg) returned false") = checkArgument( f(arg), errorMessage)


methodAsExpr(m::Method) = Meta.parse( match( FUNCTION_DEF_PATTERN, string(m) ).match )

convert(::Type{Expr}, m::Method) = methodAsExpr(m)

methodExprsWith(var) = convert.( Expr, methodswith(var) )


function formatImplemetationMethod( implementation, method::Union{Expr, Symbol} )

    implementationArg = Meta.parse( ("$implementation"[1] |> lowercase) * "::$implementation" )

    if method isa Symbol  method = :($method($implementationArg))
    else  insert!( method.args, 2, :($implementationArg) )  end

    return method
end


function makeExplicit(type::Expr)
    checkState( type.head === :(::), "argument to makeExplicit2 must be a variable name or a type declaration of the form x::X (got $type)" )
    if (type.args[end] in (:Int, :UInt))  type.args[end] = Symbol( "$(type.args[end])$(Sys.WORD_SIZE)" ) end
    return type
end

makeExplicit(type::Symbol) = return type
