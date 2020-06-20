#include("conflicts.jl")


FUNCTION_ARG_PATTERN = r"\(.*\)"
FUNCTION_DEF_PATTERN = r".*\(.*\)"


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


exists(obj, type::T=Any) where T <: Type = return obj isa type

# god what a shitty hack. You should really have this function Julia.
function exists(obj::Symbol, type::T=Any) where T <: Type
    objexists = false
    try
        objexists = eval(obj) isa type
    catch err
        if err isa UndefVarError return false
        else throw(err) end
    end
    return objexists
end

# this recurses if expr contains more exprs, so be careful
function exists(expr::Expr)
    nonexistent = filter( e-> !exists(e), expr.args )
    return nonexistent |> isempty
end

checkExists(obj::Symbol, type::T) where T <: Type = return obj isa type = checkArgument( exists(obj, type), "object $obj of type $type does not exist." )


# function getAllInterfaceMethods(interface::Type{I}) where I <: Interface
#     methodlist = string.( methodswith(interface) )
#     methodArgs = match.( FUNCTION_DEF_PATTERN, methodlist )
#     methodDefs = Meta.parse.( [ mtd.match for mtd in methodArgs ] )
#     return methodDefs
# end


function getAllMethodArgs(ftn::Function)
    # XXX this's a buncha pig piss shit hell and I'm well aware of it
    methodlist = string.( methods(ftn).ms )
    methodArgs = match.( FUNCTION_ARG_PATTERN, methodlist )
    argTuples = Meta.parse.( [ "$ftn"*mtd.match for mtd in methodArgs ] )
    # I didn't use map!() below b/c it causes a BoundsError: attempt to access ().
    # The below (using map() and reassigning) works as expected.
    # possible I'm missing something obvious
    argTuples = map((argTuple)-> if argTuple isa Symbol argTuple = :($argTuple,); else argTuple = argTuple end, argTuples)
    return argTuples
end


function makeExplicit(type::Expr)
    checkState( type.head === :(::), "argument to makeExplicit2 must be a variable name or a type declaration of the form x::X (got $type)" )
    if (type.args[end] in (:Int, :UInt))  type.args[end] = Symbol( "Int$(Sys.WORD_SIZE)" ) end
    return type
end

makeExplicit(type::Symbol) = return type
