include("checks.jl")

abstract type Interface end


struct AbstractMethodList
    interface::Type
    methods::Vector{Function}
    AbstractMethodList(interface) = new( interface, Vector{Function}() )
end


# TODO: this still needs some testing to make it foolproof

macro interface(name, abstractVars)

    checkArgument( name isa Symbol, "invalid type expression for interface $name" )
    checkArgument( abstractVars isa Expr, "invalid variable declaration expression for interface $name" )
    checkArgument( abstractVars.head === :block, "@interface $name must be followed by begin block" )

    # stripping the LineNumberNodes isn't strictly necessary but it makes the format checking much simpler
    filter!(var->!(var isa LineNumberNode), abstractVars.args)

    # WARNING: good chance a bug could find its way past the below format checking
    # what this basically does is ensure abstract vars are declared the same way
    # they are for regular structs, e.g. α::Int, β::Float, etc
    for var in abstractVars.args
        checkArgument( var isa Expr && var.head === :(::) && length(var.args) == 2,
                      "invalid variable declaration $var in interface $name" )
    end

    abstractTypeDeclaration = :(abstract type $name <: Interface end)

    templateName = Symbol("$(name)_INTERFACE_VARS")
    templateDeclaration = :(
        struct $templateName <: $name
            $(abstractVars.args...) # <--never forget you can do this
        end
    )

    methodListName = Symbol("$(name)_method_list")
    methodListDeclaration = :( $methodListName = AbstractMethodList($name) )

    # doing this w/ evals is necessary b/c the AbstractMethodList constructor call has to be called last
    eval(abstractTypeDeclaration)
    eval(templateDeclaration)
    eval(methodListDeclaration)

end


macro abstractMethod(abstractType, ftn)

    type = abstractType
    checkArgument( eval(type) <: Interface, "$abstractType is not a valid interface" )

    unimplementedErrorString = "function $(ftn) not implemented for $abstractType"
    templateErrorString = "cannot call function $(ftn) on an interface vars object ($(abstractType)_INTERFACE_VARS)"

    template = Symbol("$(abstractType)_INTERFACE_VARS")
    methodList = Symbol("$(abstractType)_method_list")

    unimplementedCall = :( $ftn(a::$abstractType) )
    templateCall = :( $ftn(t::$template) )

    unimplementedMethod = :( $unimplementedCall = error( $unimplementedErrorString ) )
    templateMethod = :( $templateCall = error( $templateErrorString ) )
    methodAdd = :( push!( $(methodList).methods, $ftn ) )

    # as above, we have to use evals b/c the push! in the methodAdd call has to be last
    eval(unimplementedMethod)
    eval(templateMethod)
    eval(methodAdd)

end


# this should be first in line in the run file, or as upstream as possible
macro checkInterfaces()
    types = subtypes(Interface)
    calls = [:(@checkVarsImplemented($arg); @checkMethodsImplemented($arg)) for arg in types]
    eval.(calls)
end


macro checkMethodsImplemented(abstractType)
    type = eval( abstractType )
    checkArgument( type <: Interface, "$abstractType is not a valid interface" )

    requiredMethodList = Symbol( "$(abstractType)_method_list" )
    # we call 'unique' below in case you shit the bed and call @abstractMethod on the same thing 100 times
    requiredMethods = eval(requiredMethodList)
    unique!( requiredMethods.methods )

    conflicts = getFunctionConflicts( type, requiredMethods.methods )
    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )
end


macro checkVarsImplemented(abstractType)
    type = eval( abstractType )
    checkArgument( type <: Interface, "$abstractType is not a valid interface" )

    typeTemplate = eval( Symbol("$(abstractType)_INTERFACE_VARS") )

    conflicts = getFieldConflicts( type, typeTemplate )
    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )
end
