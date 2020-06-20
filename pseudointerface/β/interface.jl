include("checks.jl")
include("utils.jl")


abstract type Interface end


struct AbstractMethodList
    interface::Type
    methods::Vector{Expr}
    AbstractMethodList(interface) = new( interface, Vector{Expr}() )
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
        checkArgument( var isa Expr && var.head === :(::) && length(var.args) <= 2,
                      "invalid variable declaration $var in interface $name" )
    end

    abstractTypeDeclaration = :(abstract type $name <: β_Interface end)

    templateName = Symbol("$(name)_INTERFACE_VARS")
    templateDeclaration = :(
        struct $templateName <: $name
            $(abstractVars.args...) # <--never forget you can do this
        end
    )

    methodListName = Symbol("$(name)_method_list")
    methodListDeclaration = :( $methodListName = AbstractMethodList($name) )

    eval(abstractTypeDeclaration)
    eval(templateDeclaration)
    eval(methodListDeclaration)

end


macro abstractMethod2(abstractType, methodCall)

    checkArgument( abstractType isa Symbol && eval(abstractType) <: Interface, "1st argument to @abstractMethod must be an Interface (got $abstractType)" )
    checkArgument( methodCall isa Expr && methodCall.head == :call,  "2nd argument to @abstractMethod must be a method declaration (i.e. of the form ftn(args...) (got $abstractType)" )

    methodCall.args = makeExplicit.( methodCall.args )
    functionName = methodCall.args[1]

    unimplementedErrorString = "function $(methodCall) not implemented for $abstractType"
    templateErrorString = "cannot call function $(methodCall) on an interface vars object ($(abstractType)_INTERFACE_VARS)"

    template = Symbol( "$(abstractType)_INTERFACE_VARS" )
    methodList = Symbol( "$(abstractType)_method_list" )
    checkState( :($methodList).methods  )

    methodCall = constructMethodCall( eval(abstractType), methodCall )

    unimplementedCall = :( $functionName(a::$abstractType) )
    templateCall = :( $functionName(t::$template) )
    methodCall = string( methodCall )

    unimplementedMethod = :( $unimplementedCall = error( $unimplementedErrorString ) )
    templateMethod = :( $templateCall = error( $templateErrorString ) )
    methodAdd = :( push!( $(methodList).methods, Meta.parse($methodCall) ) )

    return quote
        $unimplementedMethod
        $templateMethod
        $methodAdd
    end
end


macro checkMethodsImplemented2(interface)
    checkArgument( interface isa Symbol && eval(interface) <: Interface, "1st argument to @checkMethodsImplemented must be an Interface (got $abstractType)" )

    requiredMethods = :($interface)_method_list.methods
    type = eval(interface)

    methodsImplemented = getAllInterfaceMethods(type)


end

# this should be first in line in the run file, or as upstream as possible
macro checkInterfaces()
    types = subtypes(Interface)
    calls = [:(@checkVarsImplemented($type); @checkMethodsImplemented($type)) for type in types]
    eval.(calls)
end


macro checkMethodsImplemented(abstractType)
    checkArgument( abstractType isa Symbol, "argument to checkMethodsImplemented must be an Interface (got $abstractType)" )
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


macro checkRequiredArgs(ftn)

    checkArgument( ftn isa Expr && ftn.head === :call, "argument to checkRequiredArgs must be a valid function declaration (got $ftn)" )
    checkExists( ftn.args[1] ) # <- ftn.args[1] is the function's name, as a symbol
    checkArgument.( ftn.args, arg -> arg isa Symbol || isexpr(arg, :(::)), "arguments to $ftn must be of the form `var` or `var::V` (got $ftn)")

    functionName = ftn.args[1]
    functionArgs = makeExplicit.( ftn.args[2:end] ) # this ensures any arguments w/ type :Int are made explicity Int32 or Int64
    functionCall = Expr(:call, functionName, functionArgs...)

    checkArgument( functionCall in getAllMethodArgs( eval(functionName) ),  )

end
