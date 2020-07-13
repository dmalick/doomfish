using GLFW
include("Input.jl")


# TODO: deal w/ keeping track of what window MouseInputs apply to

struct MouseInput <: Input
    action::GLFW.Action
    button::GLFW.MouseButton
    mods::Int32
    MouseInput( action::GLFW.Action, button::GLFW.MouseButton, mods::Integer=0 ) = new( action, button, mods |> Int32 )
end

MouseInput( eventType::MouseEventType, button::GLFW.MouseButton, mods::Integer=0 ) = MouseInput( GLFW.Action( Int(eventType) ), button, mods )


# FYI, there are no performance losses using @_str syntax (e.g. mousepress"ctrl left")
# vs just calling the constructors

macro mousepress_str( command )
    button, mods = parse_MouseInput( command )
    return :( MouseInput( GLFW.PRESS, $button, $mods ) )
end

# identical to @mousepress_str, just in case "clicking the mouse"
# makes more sense than "pressing the mouse" in plain English.
# dealer's choice.
macro mouseclick_str( command ) Meta.parse( "mousepress\"$command\"" ) end


macro mouserelease_str( command )
    button, mods = parse_MouseInput( command )
    return :( MouseInput( GLFW.RELEASE, $button, $mods ) )
end


macro mouserepeat_str( command )
    button, mods = parse_MouseInput( command )
    return :( MouseInput( GLFW.REPEAT, $button, $mods ) )
end


function parse_MouseInput( command::String )
    params = split( replace( command, ","=>" " ) )
    button, mods = nothing, nothing
    try
        if length(params) == 1
            # gotta do these parse shenanigans
            button = Meta.parse( "mousebutton\"$(params[1])\"" ) |> eval
            mods = 0
        else
            button = Meta.parse( "mousebutton\"$(pop!(params))\"" ) |> eval
            mods = Meta.parse( "mods\"$(join(params, ' '))\"" ) |> eval
        end
    catch err
        @error "invalid mouse input string: \"$command\""
        throw(err)
    end
    return button, mods
end
