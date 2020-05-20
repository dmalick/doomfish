using GLFW
include("/home/gil/doomfish/doomfishjl/engine/EventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/opengl/GlWindow.jl") # includes coordinates.jl
include("inputtypes/KeyInput.jl")
include("inputtypes/MouseInput.jl")


keyInput( eventProcessor::EventProcessor, action::GLFW.action, key::GLFW.Key, mods::Int ) = enqueueInput!( eventProcessor,
                                                                                                           KeyInput( action, key, mods ) )


function mouseInput( eventProcessor::EventProcessor, window::Int64, action::GLFW.action, button::GLFW.MouseButton, mods::Int )
    @info "queueing mouse input for window $window"
    coord = getCursorPosition( window )
    if (coord |> isValidCoordinate)
        enqueueInput!( eventProcessor, MouseInput( action, button, coord, mods ) )
    else
        # Not sure if the original betamax message (below) is completely accurate
        @warn "Out of bounds $coord due to excessively delayed handling of mouse click"
    end
end
