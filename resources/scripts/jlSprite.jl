

struct JlSprite
    name::String
    layer::Int
    frameCount::Int
    repeatCount::Int
    repeatIndefinitely::Bool


    moments = Dict{ Union{Int, String}, Vector{Function} }()


    physics::PhysicsContainer


    children::Vector{ JlSprite }
    built::Bool
end
