using GLFW
include("/home/gil/doomfish/doomfishjl/opengl/coordinates.jl")
include("Input.jl")


# TODO: deal w/ keeping track of what window MouseInputs apply to

struct MouseInput <: Input
    action::GLFW.Action
    button::GLFW.MouseButton
    mods::Int32
    MouseInput( action::GLFW.Action, button::GLFW.MouseButton; mods::Integer=0 ) = new( action, button, mods |> Int32 )
end

MouseInput( eventType::MouseEventType, button::GLFW.MouseButton; mods::Integer=0 ) = MouseInput( GLFW.Action( Int(eventType) ), button, mods )
