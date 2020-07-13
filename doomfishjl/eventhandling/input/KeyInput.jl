using GLFW
include("/home/gil/doomfish/doomfishjl/eventhandling/event/EventTypes.jl")
include("Input.jl")


struct KeyInput <: Input
    action::GLFW.Action
    key::GLFW.Key
    mods::Int32
    KeyInput( action::GLFW.Action, key::GLFW.Key, mods::Integer=0 ) = new( action, key, Int32(mods) )
end

KeyInput( eventType::KeyEventType, key::GLFW.Key, mods::Integer=0 ) = KeyInput( GLFW.Action( Int(eventType) ), key, Int32(mods) )


# FYI, there are no performance losses using @_str syntax (e.g. keypress"ctrl f")
# vs just calling the constructors.

macro keypress_str( command )
    key, mods = parse_KeyInput( command )
    return :( KeyInput( GLFW.PRESS, $key, Int32($mods) ) )
end


macro keyrelease_str( command )
    key, mods = parse_KeyInput( command )
    return :( KeyInput( GLFW.RELEASE, $key, Int32($mods) ) )
end


macro keyrepeat_str( command )
    key, mods = parse_KeyInput( command )
    return :( KeyInput( GLFW.REPEAT, $key, Int32($mods) ) )
end



function parse_KeyInput( command::String )
    checkState( length(command) > 0, "invalid key/mods: $command" )
    command = replace( command, ","=>" " )
    pressed = split(command)
    key, mods = nothing, nothing
    try
        if length(pressed) == 1
            # gotta do these parse shenanigans
            key = Meta.parse( "key\"$(pressed[1])\"" ) |> eval
            mods = 0
        else
            key = Meta.parse( "key\"$(pop!(pressed))\"" ) |> eval
            mods = Meta.parse( "mods\"$(join(pressed, ' '))\"" ) |> eval
        end
    catch err
        @error "invalid key input string: \"$command\""
        throw(err)
    end
    return key, mods
end
