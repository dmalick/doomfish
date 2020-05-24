using DataStructures
include("eventtypes/Event.jl")


# the reason this whole thing is constructed around a SortedDict rather than
# a PriorityQueue is that PriorityQueues are set up w/ key => value pairs
# representing key => priority, and the keys must be unique.
# that won't work for us b/c we may have multiple instances of the same event
# queued up at the same time. Setting up the SortedDict w/ the keys representing
# the priorities and the values representing prioritized subqueues fixes this.
struct EventQueue
    ordered::SortedDict{ Int, Vector{ QueuedEvent } }
    other:: Vector{ QueuedEvent }
    EventQueue() = new( SortedDict{ Int, Vector{ QueuedEvent } }(), Vector{ QueuedEvent }() )
end


function enqueueEvent!(queue::EventQueue, ϵ::QueuedEvent)
    if nothing == ϵ.priority
        pushfirst!( queue.other, ϵ.event )
    else
        if !haskey( queue.ordered, ϵ.priority )
            queue.ordered[ ϵ.priority ] = Vector{Event}()
        end
        pushfirst!( queue.ordered[ ϵ.priority ], ϵ.event )
    end
end


function getDispatchQueue!(queue::EventQueue)
    orderedQueues = [ subqueuePair.second for subqueuePair in queue.ordered ]

    dispatchQueue = vcat( queue.other, orderedQueues... )
    # empty!. won't work on a tuple of arrays, but will work recursively on a
    # multidimensional array, hence the wrapping of the arguments below in a vector
    empty!.( [queue.other, orderedQueues...] )

    return dispatchQueue
end


struct QueuedEvent
    event::Event
    priority::Union{Int, Nothing}

    # FIXME could find a cleaner way to do this
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


function priorityOverride!(ϵ::EventQueue, event::QueuedEvent, priority::Int)
    checkArgument( event in ϵ.ordered[ event.priority ], "no such event $event in queue $(ϵ.ordered[ event.priority ])" )

    @warn "event $ϵ priority overridden to $priority"
    delete!( ϵ.ordered[ event.priority ], event )

    event.priority = priority
    pushfirst!( ϵ.ordered[ priority ], event )
end


isless(event_a::QueuedEvent, event_b::QueuedEvent) = return event_a.priority < event_b.priority
