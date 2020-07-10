using GLFW
include("Input.jl")


struct KeyInput <: Input
    action::GLFW.Action
    key::GLFW.Key
    mods::Int32
end

KeyInput( action::GLFW.Action, key::GLFW.Key ) = KeyInput( action, key, zero(Int32) )
KeyInput( eventType::KeyEventType, key::GLFW.Key ) = KeyInput( GLFW.Action( Int(eventType) ), key )
