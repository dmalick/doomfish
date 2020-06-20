include("Input.jl")


struct MouseInput <: Input
    action::GLFW.Action
    button::GLFW.MouseButton
    coordinate::TextureCoordinate
    mods::Int
end
MouseInput(action::GLFW.Action, button::GLFW.MouseButton, mods::Int) = MouseInput(action, button, TextureCoordinate(0.5, 0.5), mods)


function mouseInput!( eventProcessor::EventProcessor, window::Int64, input::MouseInput )
    @info "queueing mouse input for window $window"
    coord = getCursorPosition( window )
    if (coord |> isValidCoordinate)
        enqueueInput!( eventProcessor, MouseInput( input.action, input.button, coord, input.mods ) )
    else
        # Not sure if the original betamax message (below) is completely accurate
        @warn "Out of bounds $coord due to excessively delayed handling of mouse click"
    end
end
