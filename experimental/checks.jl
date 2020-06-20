import Base.Threads.@threads


FUNCTION_ARG_PATTERN = r"\(.*\)"


function checkState(state::Bool, errorMessage::String="invalid state: $state")
    if !state
        error( errorMessage )
    end
end


function checkArgument(conditional::Bool, errorMessage::String="$conditional not met")
    if !conditional
        throw( ArgumentError(errorMessage) )
    end
end


checkArgument(arg, f::Function, errorMessage::String="$f(arg) returned false") = checkArgument( f(arg), errorMessage)


checkExists(obj::Symbol; type::Type=Any) = checkArgument( exists(obj, type), "object $obj of type $type does not exist." )


exists(obj, type::Type=Any) = return obj isa type


# god what a shitty hack. You should really have this function Julia.
function exists(obj::Symbol, type::Type=Any)
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
    nonexistent = filter(e-> !exists( e ), expr.args)
    return nonexistent |> isempty
end


# this one recurses too, so think carefully before you go doin getprimitives(Any)
function getprimitives(superType::Type)
    subTypes = subtypes(superType)
    primitives = filter( isprimitivetype, subTypes )
    setdiff!(subTypes, primitives)
    if (subTypes |> isempty) return primitives
    else return vcat( primitives, getprimitives.(subTypes)... )
    end
end


function primitivetypes(types::Vector)
    primitives, subTypes = splitSubtypes( types )
    while !( subTypes |> isempty )
        extractedtypes = Vector()
        @threads for type in subTypes
            push!( extractedtypes, subtypes(type)... )
        end
        extractedprimitives, subTypes = splitSubtypes(extractedtypes)
        push!( primitives, extractedprimitives... )
    end
    return primitives
end


function extract(collection, getSubvals::Function, filterFtn::Function)
    extractedValues = filter( filterFtn, collection )
    remainingValues = setdiff( collection, extractedValues )

    while !(remainingValues |> isempty)
        subvals = vcat( getSubvals.(remainingValues)... )

        newExtractedValues = filter( filterFtn, subvals )
        remainingValues = setdiff( subvals, newExtractedValues )

        push!(extractedValues, newExtractedValues...)
    end
    return extractedValues
end


function primitivetypes(superType::Type; printsteps=false)
    primitives, subTypes = splitSubtypes( subtypes(superType) )
    while !( subTypes |> isempty )
        extractedsubtypes = Vector()
        @threads for type in subTypes
            # to deal w/ weird cases where types are their own subtypes (?)
            newsubtypes = setdiff(subtypes(type), [type])
            extractedprimitives = filter( isprimitivetype, subtypes(type) )
            push!(primitives, extractedprimitives...)
            remainingsubtypes = setdiff( subtypes(type), extractedprimitives )
            if length(remainingsubtypes) > 0
                push!( extractedsubtypes, remainingsubtypes... )
            end
        end


        if printsteps println(extractedprimitives) end
        #push!( primitives, extractedprimitives... )
    end
    return primitives
end

function splitSubtypes(types::Vector)
    primitives = filter( isprimitivetype, types)
    setdiff!(types, primitives)
    return primitives, types
end


# we use these to more conveniently enforce argument types in macros
isexpr(expr, exprHead::Symbol) = return ( expr isa Expr && expr.head === exprHead )
isexpr(expr, exprHeads::AbstractArray{Symbol}) = return ( expr isa Expr && expr.head in exprHeads )
isexecutable(exprHead::Symbol) = return ( exprHead in (:call, :block, :macrocall, :->) )
isexecutable(expr) = isexpr( expr, (:call, :block, :macrocall, :->) )





macro checkRequiredArgs(requiredArgs, ftn)
    checkArgument( isexpr(requiredArgs, :tuple), "first argument of @checkRequiredArgs must be a tuple of required args (got $requiredArgs)" )
    checkArgument( ftn isa Symbol && ( func = eval(ftn) ) isa Function, "second argument of @checkRequiredArgs must be a function (not a function call!) (got $ftn)" )
end


macro getAllArgs(ftn)
    checkExists( ftn, Function )
    # XXX this's a buncha pig piss shit hell and I'm well aware of it
    methodlist = string.( methods(func).ms )
    methodArgs = match.( FUNCTION_ARG_PATTERN, methodlist )
    argTuples = Meta.parse.( [ mtd.match for mtd in methodArgs ] )
    # I didn't use map!() below b/c it causes a BoundsError: attempt to access ().
    # The below (using map() and reassigning) works as expected.
    argTuples = map((argTuple)-> if argTuple isa Symbol argTuple = :(($argTuple,)); else argTuple = argTuple end, argTuples)
    return argTuples
end


function getAllMethodArgs(ftn::Function)
    # XXX this's a buncha pig piss shit hell and I'm well aware of it
    methodlist = string.( methods(ftn).ms )
    methodArgs = match.( FUNCTION_ARG_PATTERN, methodlist )
    argTuples = Meta.parse.( [ mtd.match for mtd in methodArgs ] )
    # I didn't use map!() below b/c it causes a BoundsError: attempt to access ().
    # The below (using map() and reassigning) works as expected.
    # possible I'm missing something obvious
    argTuples = map((argTuple)-> if argTuple isa Symbol argTuple = :(($argTuple,)); else argTuple = argTuple end, argTuples)
    return argTuples
end


macro checkExists(obj)
    checkExists(obj)
end
