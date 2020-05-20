include("Input.jl")


struct MouseInput <: Input
    action::GLFW.Action
    button::GLFW.MouseButton
    coordinate::TextureCoordinate
    mods::Int
end
