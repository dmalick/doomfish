import Base.show


@enum SharedEventType begin
    MOMENT
    LOGIC_FRAME_END
end


@enum KeyEventType begin
    KEY_PRESS   = Int( GLFW.PRESS )
    KEY_RELEASE = Int( GLFW.RELEASE )
    KEY_REPEAT  = Int( GLFW.REPEAT )
end


@enum MouseEventType begin
    MOUSE_BUTTON_PRESS   = Int( GLFW.PRESS )
    MOUSE_BUTTON_RELEASE = Int( GLFW.RELEASE )
    MOUSE_BUTTON_REPEAT  = Int( GLFW.REPEAT )
end


@enum GlobalOnlyEventType begin
    BEGIN
    REBOOT
end


@enum SpriteOnlyEventType begin
    # sprite events, specific to exactly one sprite
    SPRITE_CREATE
    SPRITE_DESTROY

    SPRITE_CLICK

    SPRITE_COLLIDE

    SPRITE_MOMENT
end


# WARNING the `;` suppresses the "show_datatype" call, which causes a crash w/ a union of
# more than one enum.
# seems like you oughta deal w/ that, Julia.
EventType =       Union{ SpriteOnlyEventType, GlobalOnlyEventType, KeyEventType, MouseEventType, SharedEventType };
GlobalEventType = Union{ GlobalOnlyEventType, KeyEventType, MouseEventType, SharedEventType };
SpriteEventType = Union{ SpriteOnlyEventType, KeyEventType, MouseEventType, SharedEventType };
