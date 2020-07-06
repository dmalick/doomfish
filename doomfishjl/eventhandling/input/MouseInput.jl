include("Input.jl")


struct MouseInput <: Input
    action::GLFW.Action
    button::GLFW.MouseButton
    coordinate::TextureCoordinate
    mods::Int32
end
MouseInput(action::GLFW.Action, button::GLFW.MouseButton, mods::Int32) = MouseInput(action, button, TextureCoordinate(0.5, 0.5), mods)
MouseInput(action::GLFW.Action, button::GLFW.MouseButton) = MouseInput(action, button, TextureCoordinate(0.5, 0.5), zero(Int32))


function mouseInput!( eventProcessor::EventProcessor, window::GLFW.Window, input::MouseInput )
    @info "queueing mouse input for window $window"
    coord = getCursorPosition( window )
    if (coord |> isValidCoordinate)
        enqueueInput!( eventProcessor, MouseInput( input.action, input.button, coord, input.mods ) )
    else
        # Not sure if the original betamax message (below) is completely accurate
        @warn "Out of bounds $coord due to excessively delayed handling of mouse click"
    end
end
