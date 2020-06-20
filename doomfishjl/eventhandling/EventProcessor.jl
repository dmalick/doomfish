include("/home/gil/doomfish/doomfishjl/scripting/LogicHandler.jl")
include("inputtypes/Input.jl")
include("QueuedEvent.jl")


# This structure has been simplified significantly. What the EventProcessor now
# does is map inputs to events, and tells the LogicHandler what
# events to invoke based on the gamestate, and the order in which to invoke them.
# We no longer reference specific subtypes of Events or Inputs anywhere, nor do we mess
# w/ callbacks. We'll let the LogicHandler (whatever it may be) deal w/ all that.
# Events and Inputs being abstract types, and the LogicHandler being an interface,
# any number of varying structures can be built around this single EventProcessor.


struct EventProcessor

    inputMap::Dict{ Input, Event }
    inputQueue::Vector{ Input }

    registeredEvents::Vector{ Event }
    enqueuedEvents::Vector{ QueuedEvent }

    # WARNING before I shrunk this, we kept track of the last dispatched moment w/ a variable here.
    # may need to keep track of it somewhere else (like the LogicHandler).

    acceptingRegistrations::Bool # = false

    EventProcessor() = new( Dict{Input, Event}(), Vector{Input}(), Dict{Event, Function}(), Vector{QueuedEvent}(), false )
end


# we use the popfirst! / push! style queue to be consistent w/ the event queue
enqueueInput!(ϵ::EventProcessor, input::Input) = haskey( ϵ.inputMap ) ? push!( ϵ.inputQueue, input ) : return


function processInputs!(ϵ::EventProcessor)
    while !(ϵ.inputQueue |> isempty)
        # we use the popfirst! / push! style queue to be consistent w/ the event queue
        enqueueEvent!( ϵ, ϵ.inputMap[ popfirst!(p.inputQueue) ] )
    end
end


function registerEvent!(ϵ::EventProcessor, event::Event; input::Union{Input, Nothing} = nothing)
    checkArgument( ϵ.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !( event in ϵ.registeredEvents ), "event $event already registered in EventProcessor.registeredEvents" )
    push!( ϵ.registeredEvents, event )
    if nothing != input
        ϵ.inputMap[input] = event
    end
end


function enqueueEvent!(ϵ::EventProcessor, event::Event)
    checkArgument( event in keys( ϵ.registeredEvents ) , "event $event not registered in EventProcessor.registeredEvents" )
    push!( ϵ.enqueuedEvents, QueuedEvent(event) )
end


function dispatchEvents!(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    sort!( ϵ.enqueuedEvents )
    while !(ϵ.enqueuedEvents |> isEmpty)
        # we use the push! / popfirst! (1st element first, 2nd element second, etc) style queue
        # so that when we sort it by priority we don't have to reverse the sort order
        dispatchedEvent = popfirst!(ϵ.enqueuedEvents).event
        dispatchSingleEvent( ϵ, logicHandler, dispatchedEvent )
        # TODO: a separate propagate() call used to be here. seemed like too much of an
        # implementation-specific thing, so move it to the LogicHandler.
    end
end


function dispatchSingleEvent(ϵ::EventProcessor, logicHandler::L, event::Event) where L <: LogicHandler
    @collectstats HANDLE_SINGLE_EVENT onEvent( logicHandler, event )
end
