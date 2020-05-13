

@enum EventType begin
# sprite events, specific to exactly one sprite
SPRITE_CREATE
SPRITE_DESTROY
SPRITE_CLICK
SPRITE_KEY_PRESSED
SPRITE_KEY_RELEASED
SPRITE_KEY_REPEATED
SPRITE_COLLIDE # TODO: everything for collide events
SPRITE_MOMENT # SpriteEvent.moment has meaning for this and only this EventType instance
# global events, not specific to any single sprit
BEGIN
end

@interface Event begin
    eventType::EventType
end


struct GenericEvent <: Event
    eventType::EventType
end
