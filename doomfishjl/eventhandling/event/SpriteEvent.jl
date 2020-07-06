
include("Event.jl")


# betamax:
#= An event such as an input or timing event that pertains to a single specific sprite

 XXX: not sure if this C union style is best here as opposed to an oop hierarchy, but tbqh i think it's the right
 way for a thing that has no polymorphic methods applicable anyway that belong here.
 =#

struct SpriteEvent <: Event
        eventType::SpriteEventType
        spriteName::SpriteName

        moment::Union{Int, Nothing}
        key::Union{Int, Nothing}

        function SpriteEvent(eventType::SpriteEventType, spriteName::SpriteName; moment::Union{Int, Nothing}=nothing, key::Union{Int, Nothing}=nothing, collidedWith::Union{SpriteName, Nothing}=nothing)
                checkArgument( eventType in ( SPRITE_KEY_PRESSED, SPRITE_KEY_RELEASED, SPRITE_KEY_REPEATED )
                            || key == nothing, "key may only be set for SPRITE_KEY_PRESSED, SPRITE_KEY_RELEASED, or SPRITE_KEY_REPEATED events" )
                checkArgument( eventType == SPRITE_MOMENT || moment == nothing, "moment may only be set for SPRITE_MOMENT events" )

                return new( eventType, spriteName, moment, key, collidedWith )
        end
end
