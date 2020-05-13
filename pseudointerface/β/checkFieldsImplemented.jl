include("checkState.jl")


# typeTemplate is just an implementation of abstractType containing only the fields we want to check for

macro checkFieldsImplemented(abstractType, typeTemplate)
    abstractType = eval(abstractType)
    typeTemplate = eval(typeTemplate)
    checkState( typeTemplate <: abstractType, "type $typeTemplate is not a valid implementation of $abstractType" )

    fieldConflicts = getFieldConflicts( abstractType, typeTemplate )
    checkState( fieldConflicts |> isempty, "\n"*join(fieldConflicts, "\n") )
end


macro checkSingleTypeFieldsImplemented(type, typeTemplate)
    type = eval(type)
    typeTemplate = eval(typeTemplate)
    fieldDiff = getSingleFieldConflicts( type, typeTemplate )
    checkState( fieldDiff |> isempty, "fields $fieldDiff missing or type-mismatched in implementation $type of abstract type $(typeTemplate |> supertype)" )
end



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
