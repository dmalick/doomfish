using GLFW
include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/opengl/GlWindow.jl") # includes coordinates.jl
include("KeyInput.jl")
include("MouseInput.jl")


# these pass along input data to the EventProcessor.
# they'll get assigned as the key/mousebutton callbacks for the GLFW window.


keyInput( eventProcessor::EventProcessor, action::GLFW.Action, key::GLFW.Key, mods::Int ) = enqueueInput!( eventProcessor,
                                                                                                           KeyInput( action, key, mods ) )

function mouseInput( eventProcessor::EventProcessor, window::Int64, action::GLFW.Action, button::GLFW.MouseButton, mods::Int )
    @info "queueing mouse input for window $window"
    coord = getCursorPosition( window )
    if (coord |> isValidCoordinate)
        enqueueInput!( eventProcessor, MouseInput( action, button, coord, mods ) )
    else
        # Not sure if the original betamax message (below) is completely accurate
        @warn "Out of bounds $coord due to excessively delayed handling of mouse click"
    end
end
