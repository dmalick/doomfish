include("/home/gil/doomfish/doomfishjl/eventhandling/input/KeyInput.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/input/MouseInput.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")


struct GlobalEvent <: Event

    eventType::GlobalEventType
    moment::Union{ Moment, Nothing }
    input::Union{ Input, Nothing }

    function GlobalEvent( eventType::GlobalEventType; moment = nothing, input = nothing )
        checkArgument( moment == nothing || eventType == MOMENT, "moment may only be set for Events when Event.eventType == MOMENT" )
        new( eventType, moment, input )
    end

end

GlobalEvent( input::KeyInput ) = GlobalEvent( KeyEventType( Int(input.action) ), input = input )
GlobalEvent( input::MouseInput ) = GlobalEvent( MouseEventType( Int(input.action) ), input = input )

GlobalEvent( moment::Moment ) = GlobalEvent( MOMENT, moment=moment )


GlobalEvent( eventType::KeyEventType, key::GLFW.Key; mods::UInt16=zero(UInt16) ) = GlobalEvent( eventType, input = KeyInput( eventType, key, mods ) )
GlobalEvent( eventType::MouseEventType, button::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = GlobalEvent( eventType, input = MouseInput( eventType, button, mods ) )


# below intended for scripting use only

KeyPress( key::GLFW.Key; mods::UInt16=zero(UInt16) ) = GlobalEvent( KEY_PRESS, key, mods=mods )
KeyPress( input::KeyInput ) = GlobalEvent( input )
KeyRelease( key::GLFW.Key; mods::UInt16=zero(UInt16) ) = GlobalEvent( KEY_RELEASE, key, mods=mods )
KeyRepeat( key::GLFW.Key; mods::UInt16=zero(UInt16) ) = GlobalEvent( KEY_REPEAT, key, mods=mods )

MouseClick( button::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = GlobalEvent( MOUSE_BUTTON_PRESS, button, mods=mods )
MouseRelease( button::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = GlobalEvent( MOUSE_BUTTON_RELEASE, button, mods=mods )
MouseRepeat( button::GLFW.MouseButton; mods::UInt16=zero(UInt16) ) = GlobalEvent( MOUSE_BUTTON_REPEAT, button, mods=mods )

LogicFrameEnd() = GlobalEvent( LOGIC_FRAME_END )
