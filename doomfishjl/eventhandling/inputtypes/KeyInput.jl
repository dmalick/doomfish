include("Input.jl")


struct KeyInput <: Input
    action::GLFW.Action
    key::GLFW.Key
    mods::Int
end

keyInput!(eventProcessor::EventProcessor, action::Int, key::Int, mods::Int) = enqueueInput!( eventProcessor, KeyInput(action, key, mods) )
