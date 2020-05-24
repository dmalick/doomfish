using DataStructures
import Base.isless
include("eventtypes/Event.jl")


struct QueuedEvent
    event::Event
    priority::Union{Int, Nothing}

    # FIXME could find a way to make this easier to read
    function QueuedEvent(event)
        priority = nothing
        for key in keys( EVENT_PRIORITIES )
            if event.eventType in EVENT_PRIORITIES[ key ]
                priority = key
                break
            end
        end
        return new( event, priority )
    end
end


isless(event_A::QueuedEvent, event_B::QueuedEvent) = return event_A.priority < event_B.priority


function priorityOverride!(eventQueue::Vector{QueuedEvent}, event::QueuedEvent, priority::Int)
    checkArgument( event in eventQueue, "no such event $event in event queue $eventQueue" )
    @warn "event $ϵ priority overridden to $priority"
    event.priority = priority
end
