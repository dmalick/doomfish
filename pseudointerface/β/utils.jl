

FUNCTION_ARG_PATTERN = r"\(.*\)"
FUNCTION_DEF_PATTERN = r".*\(.*\)"


function makeExplicit(type::Expr)
    checkState( type.head === :(::), "argument to makeExplicit2 must be a variable name or a type declaration of the form x::X (got $type)" )
    if (type.args[end] in (:Int, :UInt))  type.args[end] = Symbol( "Int$(Sys.WORD_SIZE)" ) end
    return type
end

makeExplicit(type::Symbol) = return type


function getAllInterfaceMethods(interface::Type{I}) where I <: Interface
    methodlist = string.( methodswith(interface) )
    methodArgs = match.( FUNCTION_DEF_PATTERN, methodlist )
    methodDefs = Meta.parse.( [ mtd.match for mtd in methodArgs ] )
    return methodDefs
end


function constructMethodCall(interface::Type{I}, methodCall::Expr) where I <: Interface
    checkArgument( methodCall.head === :call )
    name = "$interface"[1] |> string |> lowercase
    name = Meta.parse( "$name::$interface" )
    insert!( methodCall.args, 2, name )
    return methodCall
end
