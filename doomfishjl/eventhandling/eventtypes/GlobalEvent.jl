include("Event.jl")


@enum GlobalEventType begin
    BEGIN
    PROPAGATE
end


struct GlobalEvent <: Event
    eventType::GlobalEventType
end
