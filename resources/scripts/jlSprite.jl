

struct JlSprite
    name::String
    layer::Int
    frameCount::Int
    repeatCount::Int
    repeatIndefinitely::Bool


    physics::PhysicsContainer


    children::Vector{ JlSprite }
    built::Bool
end
