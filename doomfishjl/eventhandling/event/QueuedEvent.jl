import Base.isless
include("Event.jl")


# AbstractQueuedEvent is defined to allow other objects to be added to the event
# queue for special purposes, if desired.
# (e.g. LogicFrameEnd to demarkate the end of the frame)
abstract type AbstractQueuedEvent end

# we mess w/ the whole QueuedEvent abstraction rather than just doing a priority
# queue b/c Julia's PriorityQueue struct is essentially a Dict w/ value => priority
# pairs, and like any Dict, each key (in this case, the value IS the key) must be unique.
# We can't use this b/c the same event may be queued up multiple times. Instead, we
# use QueuedEvent as a wrapper and define an isless() method for it based on priority,
# and just sort!() the event queue as needed.
# WARNING could be a performance problem, we'll see.

struct QueuedEvent <: AbstractQueuedEvent
    event::Event
    priority::Union{Int, Nothing}

    # FIXME could find a way to do this better. Should be few enough event types
    # that performance for a non-prioritized event shouldn't be too affected.
    # ("should" is always risky)
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


function isless(event_A::QueuedEvent, event_B::QueuedEvent)
    if event_A.priority == nothing return true end
    if event_B.priority == nothing return false end
    return event_A.priority < event_B.priority
end


function priorityOverride!(event::QueuedEvent, priority::Int)
    @warn "event $event priority overridden to $priority"
    event.priority = priority
end
