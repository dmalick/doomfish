


abstract type Event end


struct βGlobalEvent <: Event
        eventType::EventType

        moment::Union{Int, Nothing}
        key::Union{Int, Nothing}

        callback::Function
end


struct βSpriteEvent <: Event
        eventType::EventType
        spriteName::SpriteName

        callback::Function

        moment::Union{Int, Nothing}
        key::Union{Int, Nothing}

        function βSpriteEvent(eventType::EventType, spriteName::SpriteName; callback=, moment=nothing, key=nothing)
                checkArgument( eventType == SPRITE_KEY_PRESSED || eventType == SPRITE_KEY_RELEASED || eventType == SPRITE_KEY_REPEATED
                            || key == nothing, "key may only be set for SPRITE_KEY_PRESSED, SPRITE_KEY_RELEASED, or SPRITE_KEY_REPEATED events" )
                checkArgument( eventType == SPRITE_MOMENT || moment == nothing, "moment may only be set for SPRITE_MOMENT events" )
                checkArgument( spriteName != nothing || eventType == BEGIN, "sprite must be set for sprite events" )
                checkArgument( spriteName == nothing || eventType != BEGIN, "sprite may not be set for BEGIN event" )

                return new( eventType, spriteName, callback, moment, key )
        end
end
