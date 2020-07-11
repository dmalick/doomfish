include("/home/gil/doomfish/doomfishjl/eventhandling/input/KeyInput.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/input/MouseInput.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")


struct GlobalEvent <: Event

    eventType::GlobalEventType
    moment::Union{ Int, String, Nothing }
    input::Union{ Input, Nothing }

    GlobalEvent( eventType::GlobalEventType; moment = nothing, input = nothing ) = new( eventType, moment, input )

end


GlobalEvent( eventType::KeyEventType, key::GLFW.Key; mods::UInt16=zero(UInt16) ) = GlobalEvent( eventType, input = KeyInput( eventType, key, mods ) )
GlobalEvent( eventType::MouseEventType, button::GLFW.MouseButton ) = GlobalEvent( eventType, input = MouseInput( eventType, button ) )
