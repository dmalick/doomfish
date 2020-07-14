include("/home/gil/doomfish/doomfishjl/eventhandling/input/Input.jl")
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")


struct SpriteEvent <: Event

    name::SpriteName
    eventType::SpriteEventType

    moment::Union{ Moment, Nothing }
    input::Union{ Input, Nothing }

    SpriteEvent( name, eventType; moment = nothing, input = nothing ) = new( name, eventType, moment, input )

end

# hasmoment(event::Union{GlobalEvent, SpriteEvent}) = return event.moment != nothing
# isLogicFrameEnd(event::Union{GlobalEvent, SpriteEvent}) = return hasmoment(event) && event.moment ==


SpriteEvent( name::SpriteName, input::KeyInput ) = SpriteEvent( name, KeyEventType( Int(input.action) ), input=input )
SpriteEvent( name::SpriteName, input::MouseInput ) = SpriteEvent( name, MouseEventType( Int(input.action) ), input=input )





SpriteEvent( name::SpriteName, moment::Moment ) = SpriteEvent( name, MOMENT, moment=moment )

SpriteEvent( name::SpriteName, eventType::KeyEventType, key::GLFW.Key; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, eventType, input = KeyInput( eventType, key, mods=mods ) )
SpriteEvent( name::SpriteName, eventType::MouseEventType, mouseButton::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, eventType, input = MouseInput( eventType, mouseButton, mods=mods ) )


# below intended mainly for scripting

KeyPress( name::SpriteName, key::GLFW.Key; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, KEY_PRESS, key, mods )
KeyRelease( name::SpriteName, key::GLFW.Key; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, KEY_RELEASE, key, mods )
KeyRepeat( name::SpriteName, key::GLFW.Key; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, KEY_REPEAT, key, mods )

Moment( name::SpriteName, moment::Union{Int, String} ) = SpriteEvent( spriteName, MOMENT, moment=moment )

MouseClick( name::SpriteName, button::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, MOUSE_BUTTON_PRESS, button, mods=mods )
MouseRelease( name::SpriteName, button::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, MOUSE_BUTTON_RELEASE, button, mods=mods )
MouseRepeat( name::SpriteName, button::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = SpriteEvent( name, MOUSE_BUTTON_REPEAT, button, mods=mods )

LogicFrameEnd( name::SpriteName ) = SpriteEvent( name, LOGIC_FRAME_END )
