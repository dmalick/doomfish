include("checks.jl")


abstract type Interface end


struct AbstractMethodList_β
    interface_β::Type
    methods::Dict{Function, Tuple}
    AbstractMethodList_β(interface_β) = new( interface_β, Dict{Function, Tuple}() )
end


# TODO: this still needs some testing to make it foolproof

macro interface_β(name, abstractVars)

    checkArgument( name isa Symbol, "invalid type expression for interface_β $name" )
    checkArgument( abstractVars isa Expr, "invalid variable declaration expression for interface_β $name" )
    checkArgument( abstractVars.head === :block, "@interface_β $name must be followed by begin block" )

    # stripping the LineNumberNodes isn't strictly necessary but it makes the format checking much simpler
    filter!(var->!(var isa LineNumberNode), abstractVars.args)

    # WARNING: good chance a bug could find its way past the below format checking
    # what this basically does is ensure abstract vars are declared the same way
    # they are for regular structs, e.g. α::Int, β::Float, etc
    for var in abstractVars.args
        checkArgument( var isa Expr && var.head === :(::) && length(var.args) == 2,
                      "invalid variable declaration $var in interface_β $name" )
    end

    abstractTypeDeclaration = :(abstract type $name <: Interface end)

    templateName = Symbol("$(name)_INTERFACE_VARS")
    templateDeclaration = :(
        struct $templateName <: $name
            $(abstractVars.args...) # <--never forget you can do this
        end
    )

    methodListName = Symbol("$(name)_method_list")
    methodListDeclaration = :( $methodListName = AbstractMethodList_β($name) )

    # doing this w/ evals is necessary b/c the AbstractMethodList_β constructor call has to be called last
    eval(abstractTypeDeclaration)
    eval(templateDeclaration)
    eval(methodListDeclaration)

end


macro abstractMethod_β(abstractType, ftn, args)

    type = abstractType
    arguments = args
    checkArgument( eval(type) <: Interface, "$abstractType is not a valid interface_β" )
    checkArgument( eval(arguments) isa Tuple, "invalid argument structure: $args must be a Tuple, not a $(typeof(args))"

    unimplementedErrorString = "function $(ftn) not implemented for $abstractType"
    templateErrorString = "cannot call function $(ftn) on an interface_β vars object ($(abstractType)_INTERFACE_VARS)"

    template = Symbol("$(abstractType)_INTERFACE_VARS")
    methodList = Symbol("$(abstractType)_method_list")

    unimplementedCall = :( $ftn(a::$abstractType) )
    templateCall = :( $ftn(t::$template) )

    unimplementedMethod = :( $unimplementedCall = error( $unimplementedErrorString ) )
    templateMethod = :( $templateCall = error( $templateErrorString ) )
    methodAdd = :( $(methodList).methods[$ftn] = args )

    # as above, we have to use evals b/c the push! in the methodAdd call has to be last
    eval(unimplementedMethod)
    eval(templateMethod)
    eval(methodAdd)

end


macro checkMethodsImplemented_β(abstractType)
    type = eval( abstractType )
    checkArgument( type <: Interface, "$abstractType is not a valid interface_β" )

    requiredMethodList = Symbol( "$(abstractType)_method_list.methods" )
    # we call 'unique' below in case you shit the bed and call @abstractMethod_β on the same thing 100 times
    requiredMethods = unique( eval(requiredMethodList) )

    conflicts = getFunctionConflicts( type, requiredMethods )
    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )
end


macro checkVarsImplemented_β(abstractType)
    type = eval( abstractType )
    checkArgument( type <: Interface, "$abstractType is not a valid interface_β" )

    typeTemplate = eval( Symbol("$(abstractType)_INTERFACE_VARS") )

    conflicts = getFieldConflicts( type, typeTemplate )
    checkState( conflicts |> isempty, "\n"*join(conflicts, "\n") )
end
