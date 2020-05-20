include("Input.jl")


struct KeyInput <: Input
    action::GLFW.Action
    key::GLFW.Key
    mods::Int
end
