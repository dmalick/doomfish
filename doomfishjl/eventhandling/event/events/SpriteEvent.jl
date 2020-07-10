include("/home/gil/doomfish/doomfishjl/eventhandling/input/Input.jl")
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")


struct SpriteEvent <: Event

    name::SpriteName
    eventType::SpriteEventType

    moment::Union{ Int, Nothing }
    input::Union{ Input, Nothing }

    SpriteEvent( name, eventType; moment = nothing, input = nothing ) = new( name, eventType, moment, input )

end

SpriteEvent( name::SpriteName, eventType::KeyEventType, key::GLFW.Key ) = SpriteEvent( name, eventType, input = KeyInput( eventType, key ) )
SpriteEvent( name::SpriteName, eventType::MouseEventType, mouseButton::GLFW.MouseButton ) = SpriteEvent( name, eventType, input = MouseInput( eventType, mouseButton ) )
