include("EventType.jl")


struct GlobalEvent <: Event
    eventType::EventType
end
