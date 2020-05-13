

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

# FUNCTIONS

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

# FIELDS

function getFieldConflicts( abstractType::T, typeTemplate::T ) ::Vector{String}  where T <: Type
    conflicts = Vector{String}()

    for subtype in subtypes(abstractType)
        fieldConflicts = getSingleFieldConflicts(subtype, typeTemplate)
        if !( fieldConflicts |> isempty )
            push!( conflicts, "fields $fieldConflicts missing or type-mismatched in implementation $subtype of abstract type $abstractType" )
        end
    end
    return conflicts
end

function getSingleFieldConflicts( type::T, typeTemplate::T )  where T <: Type
    fields = Dict( zip( fieldnames(type), fieldtypes(type) ) )
    requiredFields = Dict( zip( fieldnames(typeTemplate), fieldtypes(typeTemplate) ) )

    return setdiff(requiredFields, fields)
end
