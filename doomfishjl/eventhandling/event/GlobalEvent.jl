include("Event.jl")


struct GlobalEvent <: Event
    eventType::GlobalEventType
end
