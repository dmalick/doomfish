using GLFW
import Base.|
include("/home/gil/doomfish/pseudointerface/checks.jl")


abstract type Input end


macro key_str( key )
    key = lowercase( key )

    key = replace( key, '-'=>'_' )
    key = replace( key, "l_"=>"left_" )
    key = replace( key, "r_"=>"right_" )
    key = replace( key, "scrolleft_"=>"scroll_" ) # scroll lock is the one case where replacing "l_" wasn't safe

    key = replace( key, "ctrl"=>"control" ) # obvious
    key = replace( key, "equals"=>"equal" )
    key = replace( key, "tilde"=>"grave_accent" ) # `seriously?`
    key = replace( key, "numpad"=>"kp" )
    key = replace( key, "numlock"=>"num_lock" )
    key = replace( key, "capslock"=>"caps_lock" )

    key = uppercase( key )
    key = "GLFW.KEY_$key"
    return Meta.parse(key)
end


macro action_str( action )
    action = replace( action, "click"=>"press" ) # more logical for mouse use contexts
    action = replace( action, "hold"=>"repeat" ) # ditto, but works for keys as well
    action = uppercase(action)
    action = Meta.parse("GLFW.$action")
    checkArgument( eval(action) isa GLFW.Action, "$action not a valid GLFW.Action" )
    return action
end


macro mousebutton_str( button )
    button = uppercase(button)
    button = "GLFW.MOUSE_BUTTON_$button"
    return Meta.parse(button)
end


# even if you hate the @_str syntax, these should still be useful

@enum Mod begin
    SHIFT = 0x0001
    CTRL = 0x0002
    ALT = 0x0004
    SUPER = 0x0008
    CAPSLOCK = 0x0010
    NUMLOCK = 0x0020
end

|(a::Mod, b::Mod) = UInt16(a)|UInt16(b)
|(a::UInt16, b::Mod) = a|UInt16(b)


macro mods_str( modstring )
    modstring = replace( modstring, ","=>" " )
    # it looks hilarious, but it makes catching errors so much easier
    mods = uppercase.( split(modstring) )
    try checkState.( isa.(eval.(Symbol.(mods)), Mod) )
    catch err
        @error """"$modstring" not valid mod(s)\nvalid mods are: shift, ctrl, alt, super, capslock, numlock"""
        throw(err)
    end
    mods = Meta.parse( join( mods, "|" ) )
    return :( UInt16( $mods ) )
end
