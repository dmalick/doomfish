using GLFW
include("Input.jl")


struct KeyInput <: Input
    action::GLFW.Action
    key::GLFW.Key
    mods::Int32
    KeyInput( action::GLFW.Action, key::GLFW.Key, mods::Integer=0 ) = new( action, key, Int32(mods) )
end

KeyInput( eventType::KeyEventType, key::GLFW.Key, mods::Integer=0 ) = KeyInput( GLFW.Action( Int(eventType) ), key, Int32(mods) )
