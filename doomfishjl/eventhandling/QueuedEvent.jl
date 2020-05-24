using DataStructures
import Base.isless
include("eventtypes/Event.jl")


# we mess w/ the whole QueuedEvent abstraction rather than just doing a priority
# queue b/c Julia's PriorityQueue struct is essentially a Dict w/ value => priority
# pairs, and like any Dict, each key (in this case, the value IS the key) must be unique.
# We can't use this b/c the same event may be queued up multiple times. Instead, we
# use QueuedEvent as a wrapper and define an isless() method for it based on priority,
# and just sort!() the event queue as needed.


struct QueuedEvent
    event::Event
    priority::Union{Int, Nothing}

    # FIXME could find a way to do this better. Should be few enough event types
    # that performance for a non-prioritized event shouldn't be too affected.
    # (However, "should" is a risky word)
    function QueuedEvent(event::Event)
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
    @warn "event $event priority overridden to $priority"
    event.priority = priority
end
