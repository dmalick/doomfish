include("utils.jl")


abstract type Interface end

macro interface(name, body)
    checkArgument( name isa Symbol )
    checkArgument( body isa Expr && body.head === :block )

    filter!( arg-> !( arg isa LineNumberNode ), body.args )
    checkArgument.( body.args, var-> var isa Symbol || var.head === :(::) )

    templateName = Symbol("$(name)_template")
    abstractMethods = Symbol("$(name)_abstract_methods")
    templateError = "cannot instantiate an interface template ($templateName)"

    # doing evals here b/c for some reason the $abstractMethods = Vector{Expr}()
    # call doesn't register in a normal quote block. Fuckin macros
    eval( :(abstract type $name <: Interface end) )
    eval( :(struct $templateName <: $name
                $(body.args...)
                $templateName($(body.args...)) = error($templateError)
            end) )
    eval( :($abstractMethods = Vector{ Union{Expr, Symbol} }()) )

end


macro abstractMethod(interface, method)
    checkArgument( interface isa Symbol && eval(interface) <: Interface )
    checkArgument( method isa Symbol || (method isa Expr && method.head === :call) )

    if method isa Expr
        checkArgument.( method.args, var-> var isa Symbol || var.head === :(::), "invalid method declaration: $method" )
        makeExplicit.( method.args )
    end

    methodList = eval( Symbol("$(interface)_abstract_methods") )
    push!( methodList, method )
    unique!( methodList )

    if (method isa Symbol)  unimplementedMethod = :($method())
    else unimplementedMethod = copy(method) end

    insert!( unimplementedMethod.args, 2, :(i::$interface) )

    errorMsg = "method $unimplementedMethod not implemented for interface $(interface)"
    return :($unimplementedMethod = error( $errorMsg ))

end


include("conflicts.jl")


macro checkFieldsImplemented(interface)
    checkArgument( interface isa Symbol && eval(interface) <: Interface )

    interface = eval( interface )
    template = eval( Symbol("$(interface)_template") )

    conflicts = getFieldConflicts.( interface, subtypes(interface), template )
    filter!( c-> c!= nothing, conflicts )

    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )
end


macro checkMethodsImplemented(interface)
    checkArgument( interface isa Symbol && eval(interface) <: Interface )

    interface = eval( interface )
    template = eval( Symbol("$(interface)_template") )
    requiredMethods = eval( Symbol("$(interface)_abstract_methods") )

    implementedMethods = Dict{Type, Vector{Expr}}( zip( subtypes(interface), methodExprsWith.( subtypes(interface) ) ) )
    delete!( implementedMethods, template )

    conflicts = getMethodConflicts( requiredMethods, implementedMethods, interface )

    checkState( conflicts|> isempty, "\n"*join(conflicts,"\n"))
end
