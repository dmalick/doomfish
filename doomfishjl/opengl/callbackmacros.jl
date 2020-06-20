using GLFW
include("/home/gil/doomfish/pseudointerface/interface/utils.jl")


# WARNING: DO NOT USE. Weird scope problem when called within a function, not yet solved.

# the GlWindow passes a specific set of arguments to each input callback, so
# we have the stock callbacks defined to pass values into our own callback functions.
# these macros just make the code easier to read.

callbackErrorString(callbackFunction::Union{Symbol, Expr}) = return callbackFunction isa Expr ? string(callbackFunction) * " w/ head :" * string(callbackFunction.head) : "Symbol :"*string(callbackFunction)

macro keyCallback(callbackFunction)
    checkArgument( callbackFunction |> isexecutable, "@keyCallback can only be called on a function call or begin block (got $( callbackErrorString(callbackFunction) ))" )

    @info "assigning keyCallback(window::GLFW.Window, key::GLFW.Key, scancode::Int, action::GLFW.Action, mods::Int) = $callbackFunction"
    return :(keyCallback( window::GLFW.Window, key::GLFW.Key, scancode::Int, action::GLFW.Action, mods::Int ) = $callbackFunction)
end


macro mouseButtonCallback(callbackFunction)
    checkArgument( callbackFunction |> isexecutable, "@mouseButtonCallback can only be called on a function call or begin block (got $( callbackErrorString(callbackFunction) ))" )

    @info "assigning mouseButtonCallback(window::GLFW.Window, button::GLFW.Button, action::GLFW.Action, mods::Int) = $callbackFunction"
    return :(mouseButtonCallback(window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Int) = $callbackFunction)
end
