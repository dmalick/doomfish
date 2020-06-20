import Base.show

@enum GlobalEventType begin
    BEGIN
    MOMENT
    PROPAGATE

    KEY_PRESSED
    KEY_RELEASED
    KEY_REPEATED

    MOUSE_CLICK
    MOUSE_RELEASE

    REBOOT
end


@enum SpriteEventType begin
    # sprite events, specific to exactly one sprite
    SPRITE_CREATE
    SPRITE_DESTROY

    SPRITE_CLICK

    SPRITE_KEY_PRESSED
    SPRITE_KEY_RELEASED
    SPRITE_KEY_REPEATED

    SPRITE_COLLIDE

    SPRITE_MOMENT
end


# WARNING the `;` suppresses the "show_datatype" call, which causes a crash w/ a union of
# more than one enum.
# seems like you oughta deal w/ that, Julia.
EventType = Union{SpriteEventType, GlobalEventType};
