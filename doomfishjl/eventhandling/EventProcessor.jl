
include("event/QueuedEvent.jl") # includes Event.jl
include("AbstractEventProcessor.jl")
include("logic/DefaultLogic.jl")


# a queueable unique object for signaling when to stop event dispatch
# and wait for the next logic frame.
struct LogicFrameEnd <: AbstractQueuedEvent end


# differs from the first incarnation of the EventProcessor in that we no longer
# deal w/ event registration directly, and instead construct the EventProcessor
# from a separate EventRegistry which is only instantiated during script loading,
# before the world has begun. The EventProcessor is then created at the same time
# the world is, and is therefore not directly modifiable by scripts.

struct EventProcessor <: AbstractEventProcessor
    inputQueue::Vector{ Input }
    inputMap::Dict{ Input, Vector{Event} }

    eventQueue::Vector{ AbstractQueuedEvent }
    registeredEvents::Vector{ Event }
end


function EventProcessor( ρ::EventRegistry )
    inputMap = Dict{ Input, Vector{Event} }( input => filter( event -> event.input == input, ρ.registeredEvents )
                                             for input in ρ.registeredInputs )

    @info "EventProcessor created from EventRegistry $ρ"
    return EventProcessor( Vector{ Input }(), inputMap, Vector{ Event }(), ρ.registeredEvents )
end


# input handling

enqueueInput!( ϵ::EventProcessor, input::Input ) = haskey( ϵ.inputMap, input ) ? push!( ϵ.inputQueue, input ) : return

function processInputs!( ϵ::EventProcessor )
    while !(ϵ.inputQueue |> isempty)
        for event in ϵ.inputMap[ popfirst!(ϵ.inputQueue) ]
            enqueueEvent!( ϵ, event )
        end
    end
end


# event processing

function enqueueEvent!( ϵ::EventProcessor, event::Event )
    checkArgument( event in ϵ.registeredEvents , "event $event not registered in EventProcessor.registeredEvents.\n(Registered events: $(ϵ.registeredEvents))" )
    push!( ϵ.eventQueue, QueuedEvent(event) )
end


function dispatchEvents!( ϵ::EventProcessor, logicHandler::AbstractLogicHandler )
    # we use the push! / popfirst! (1st element first, 2nd element second, etc) style queue
    # so that when we sort it by priority we don't have to reverse the sort order
    sort!( ϵ.eventQueue )
    # since dispatched events can themselves add more events to the eventQueue, we
    # push! a unique LogicFrameEnd object to the queue before dispatching events to
    # signal when the queue should stop and wait for the next logic frame.
    push!( ϵ.eventQueue, LogicFrameEnd() )

    while (nextQueuedEvent = popfirst!(ϵ.eventQueue)) !== LogicFrameEnd()
        onEvent( logicHandler, nextQueuedEvent.event )
    end
    # the LOGIC_FRAME_END event is dispatched after all other events in a single logic frame,
    # intended as a propagation/cleanup step. I debated making this a requirement at all, but
    # if the AbstractLogicHandler implementation has no use for it, it can just implement an empty call.
    onLogicFrameEnd( logicHandler )
end
