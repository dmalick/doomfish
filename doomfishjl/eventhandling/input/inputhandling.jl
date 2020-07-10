using GLFW
include("/home/gil/doomfish/doomfishjl/eventhandling/AbstractEventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/opengl/GlWindow.jl") # includes coordinates.jl
include("KeyInput.jl")
include("MouseInput.jl")


# these pass along input data to the EventProcessor.
# they'll get assigned as the key/mousebutton callbacks for the GLFW window.


keyInput( eventProcessor::AbstractEventProcessor, action::GLFW.Action, key::GLFW.Key ) = enqueueInput!( eventProcessor,
                                                                                                KeyInput( action, key ) )

function mouseInput( eventProcessor::AbstractEventProcessor, window::Int64, action::GLFW.Action, button::GLFW.MouseButton )
    @info "queueing mouse input for window $window"
    coord = getCursorPosition( window )
    if (coord |> isValidCoordinate)
        enqueueInput!( eventProcessor, MouseInput( action, button, coord, zero(Int32) ) )
    else
        # Not sure if the original betamax message (below) is completely accurate
        @warn "Out of bounds $coord due to excessively delayed handling of mouse click"
    end
end
