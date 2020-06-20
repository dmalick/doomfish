using OrderedCollections
include("utils.jl")


function getFieldConflicts( interface::Type{I}, implementation::Type{J}, template::Type{K} )  where K <: I where J <: I where I <: Interface
    fields = Dict( zip( fieldnames(implementation), fieldtypes(implementation) ) )
    requiredFields = Dict( zip( fieldnames(template), fieldtypes(template) ) )

    conflicts = setdiff(requiredFields, fields)
    if !( conflicts |> isempty )
        return "fields $conflicts missing or type-mismatched in implementation $implementation of Interface $interface"
    end
end


function getMethodConflicts( requiredMethods::Vector{ Union{Expr, Symbol} },
                             implementedMethods::Dict{ Type, Vector{ Union{Expr, Symbol} } },
                             I::Interface )

    for pair in implementedMethods
        if pair.second |> isempty continue end
        for method in pair.second
            # method.args[2] is the first argument to the method call, and its own .args[2] is the type of the first argument, i.e. arg::Type
            if ( method isa Expr && method.args[2].args[2] === Symbol(pair.first) )  deleteat!( method.args, 2 ) end
        end
    end

    conflicts = Dict()
    for pair in implementedMethods
        conflicts[pair.first] = setdiff( requiredMethods, pair.second )
    end

    filter!( pair-> !isempty( pair.second ), conflicts )
    if !( conflicts |> isempty )
        return [ "method $method not implemented for implementation {$(pair.first)} of Interface $I" for pair in conflicts for method in pair.second ]
    end
end
