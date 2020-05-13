include("checkState.jl")


# macro abstractMethod(abstractType, typeTemplate, ftn)
#     unimplementedErrorString = "function $(ftn) not implemented for $abstractType"
#     templateErrorString = "cannot call function $(ftn) on a template ($typeTemplate)"
#
#     unimplementedCall = :($ftn(a::$abstractType))
#     templateCall = :($ftn(t::$typeTemplate))
#
#     unimplementedMethod = :($unimplementedCall = @error $unimplementedErrorString)
#     templateMethod = :($templateCall = @error $templateErrorString)
#     return eval(unimplementedMethod), eval(templateMethod)
# end

macro checkMethodsImplemented(abstractType)
    type = eval(abstractType)
    if !(type <: Interface)
        throw( ArgumentError("$abstractType is not a valid interface") )
    end

    requiredMethodList = Symbol( "$(abstractType)_method_list.methods" )
    requiredMethods = unique( eval(requiredMethodList) )

    conflicts = getFunctionConflicts( type, requiredMethods )
    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )

end


macro checkFunctionsImplemented(abstractType, requiredFunctions)
    type = eval(abstractType)
    functions = unique( eval(requiredFunctions) ) # in case for some reason I shit the bed and feed it [zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!, zip!...]

    conflicts = getFunctionConflicts( type, functions )
    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )
end


macro checkFunctionImplemented(abstractType, requiredFunction)
    type = eval(abstractType)
    ftn = eval(requiredFunction)
    conflicts = getSingleFunctionConflicts( type, ftn )
    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )
end


function getFunctionConflicts(type::Type, functions::Vector{F}) where F <: Function
    conflicts =[]
    for ftn in functions
        conflicts = vcat( conflicts, getSingleFunctionConflicts(type, ftn) )
    end
    return conflicts
end


function getSingleFunctionConflicts(type::Type, ftn::Function)
    conflicts = []
    for subtype in subtypes(type)
        if ( methodswith(subtype, ftn) |> isempty )
            push!(conflicts, "method of function ($ftn) not implemented for implementation {$subtype} of abstract type $type")
        end
    end
    return conflicts
end
