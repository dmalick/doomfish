using GLFW
include("/home/gil/doomfish/doomfishjl/opengl/coordinates.jl")
include("Input.jl")


struct MouseInput <: Input
    action::GLFW.Action
    button::GLFW.MouseButton
    coordinate::Union{ TextureCoordinate, Nothing }
    mods::Int32
end
MouseInput( action::GLFW.Action, button::GLFW.MouseButton; coordinate::Union{ TextureCoordinate, Nothing }=nothing, mods::Int32=zero(Int32) ) = MouseInput( action, button, coordinate, mods )


MouseInput( eventType::MouseEventType, button::GLFW.MouseButton ) = MouseInput( GLFW.Action( Int(eventType) ), button )


# overloads registerInput!( inputMap::Dict{ Input, Vector{Event} }, event::Event, input::Input ) in Input.jl
function registerInput!( inputMap::Dict{ Input, Vector{Event} }, event::Event, input::MouseInput )
    checkState( input.coordinate == nothing, "could not register $(input); cannot register a MouseInput with specified coordinates (required nothing, got $(input.coordinate))" )
    registerInput_finalize!( inputMap, event, input ) # (see Input.jl)
end


function inputToEvents(  inputMap::Dict{ Input, Vector{Event} }, input::MouseInput ) :: Vector{ Event }
    # ( the generic MouseInput is just the input stripped of coordinates )
    genericInput = MouseInput( input.action, input.button, mods = input.mods )
    templateEvents = inputMap[ genericInput ]
    return map( event -> event.input = input, templateEvents )
end
