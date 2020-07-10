include("Event.jl")


struct GlobalEvent <: Event
    eventType::GlobalEventType
    moment::Union{ Int, String, Nothing }
    key::Union{ GLFW.Key, Nothing }

    function GlobalEvent( eventType::GlobalEventType; moment = nothing, key = nothing )
        if key != nothing checkArgument( eventType in ( KEY_PRESSED, KEY_RELEASED, KEY_REPEATED ), "key ($key) may only be specified for GlobalEventTypes (KEY_PRESSED, KEY_RELEASED, KEY_REPEATED)" ) end
        if moment != nothing checkArgument( eventType === MOMENT, "moment ($moment) may only be specified for GlobalEventType MOMENT" ) end
        return new( eventType, moment, key )
    end
end
