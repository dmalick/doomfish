include("event/QueuedEvent.jl")
include("event/GlobalEvent.jl")
include("input/MouseInput.jl")
include("AbstractEventProcessor.jl")



# a queueable unique object for signaling when to stop event dispatch
# and wait for the next logic frame.
struct LogicFrameEnd <: AbstractQueuedEvent end

# these event types occur only at predefined times, and cannot be queued.
EXCLUDED_EVENTS = [ GlobalEvent( BEGIN ), GlobalEvent( LOGIC_FRAME_END ) ]

# The EventProcessor maps inputs to events, and tells the AbstractLogicHandler what
# events to invoke based on the gamestate, and the order in which to invoke them.
# We no longer reference specific subtypes of Events or Inputs anywhere, nor do we
# register callbacks. We'll let the AbstractLogicHandler (whatever it may be) deal w/ that.
# Events and Inputs being abstract types, and the AbstractLogicHandler being an interface,
# any number of varying structures can be built around this single EventProcessor.

mutable struct EventProcessor_1 <: EventProcessor

    inputMap::Dict{ Input, Vector{ Event } }
    inputQueue::Vector{ Input }

    registeredEvents::Vector{ Event }
    eventQueue::Vector{ AbstractQueuedEvent }

    # WARNING before I shrunk this, we kept track of the last dispatched moment w/ a variable here.
    # may need to keep track of it somewhere else (probably the GlProgram itself).

    acceptingRegistrations::Bool # = false

    EventProcessor_1() = new( Dict{Input, Event}(), Vector{Input}(), Vector{Event}(), Vector{QueuedEvent}(), false )
end

hasevent( ϵ::EventProcessor_1, event::Event ) = return event in ϵ.registeredEvents



# Input handling functions

registerInput!( ϵ::EventProcessor_1, event::Event ) = registerInput!( ϵ.inputMap, event, event.input ) # (see Input.jl)

# we use the popfirst! / push! style queue to be consistent w/ the event queue
enqueueInput!( ϵ::EventProcessor_1, input::Input ) = haskey( ϵ.inputMap, input ) ? push!( ϵ.inputQueue, input ) : return


function processInputs!( ϵ::EventProcessor_1 )
    # we use the popfirst! / push! style queue to be consistent w/ the event queue
    while !(ϵ.inputQueue |> isempty)
        generatedEvents = inputToEvents( ϵ.inputMap, popfirst!(ϵ.inputQueue) ) # (see Input.jl)
        enqueueEvent!.( ϵ, generatedEvents )
    end
end



# Event handling functions

function registerEvent!( ϵ::EventProcessor_1, event::Event )
    checkArgument( !( event in EXCLUDED_EVENTS ), "$event cannot be registered. It gets called automatically at a predefined time." )
    checkState( ϵ.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !hasevent( ϵ, event ), "event $event already registered in EventProcessor_1.registeredEvents" )

    push!( ϵ.registeredEvents, event )
    if hasfield( typeof(event), :input ) && event.input != nothing
        registerInput!( ϵ, event )
    end
end


function enqueueEvent!( ϵ::EventProcessor_1, event::Event )
    checkArgument( !( event in EXCLUDED_EVENTS ), "$event cannot be manually enqueued. It gets called automatically at a predefined time." )
    checkArgument( hasevent( ϵ, event ) , "event $event not registered in EventProcessor_1.registeredEvents.\n(Registered events: $(ϵ.registeredEvents))" )
    push!( ϵ.eventQueue, QueuedEvent(event) )
end


function dispatchEvents!( ϵ::EventProcessor_1, logicHandler::AbstractLogicHandler )
    # we use the push! / popfirst! (1st element first, 2nd element second, etc) style queue
    # so that when we sort it by priority we don't have to reverse the sort order
    sort!( ϵ.eventQueue )
    # since dispatched events can themselves add more events to the eventQueue, we
    # push! a unique LogicFrameEnd object to the queue before dispatching events to
    # signal when the queue should stop and wait for the next logic frame.
    push!( ϵ.eventQueue, LogicFrameEnd() )

    while (nextQueuedEvent = popfirst!(ϵ.eventQueue)) !== LogicFrameEnd()
        dispatchSingleEvent( ϵ, logicHandler, nextQueuedEvent.event )
    end
    # the LOGIC_FRAME_END event is dispatched after all other events in a single logic frame,
    # intended as a propagation/cleanup step. I debated making this a requirement at all, but
    # if the AbstractLogicHandler implementation has no use for it, it can just implement an empty call.
    dispatchLogicFrameEnd( logicHandler )
end


function dispatchSingleEvent( ϵ::EventProcessor_1, logicHandler::AbstractLogicHandler, event::Event )
    checkArgument( hasevent( ϵ, event ), "event $event not registered in EventProcessor_1.\n(Registered events: $(ϵ.registeredEvents))" )
    @debug "$(event.eventType)"
    #@collectstats HANDLE_SINGLE_EVENT
    onEvent( logicHandler, event )
end


function dispatchLogicFrameEnd( logicHandler::AbstractLogicHandler )
    # @collectstats HANDLE_SINGLE_EVENT
    @debug "LOGIC_FRAME_END"
    onLogicFrameEnd( logicHandler )
end
