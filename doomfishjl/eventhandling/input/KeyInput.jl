include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
include("Input.jl")


struct KeyInput <: Input
    action::GLFW.Action
    key::GLFW.Key
    mods::Int32
end

KeyInput( action::GLFW.Action, key::GLFW.Key ) = KeyInput( action, key, zero(Int32) )


keyInput!(eventProcessor::EventProcessor, action::GLFW.Action, key::GLFW.Key, mods::Int32) = enqueueInput!( eventProcessor, KeyInput(action, key, mods) )
