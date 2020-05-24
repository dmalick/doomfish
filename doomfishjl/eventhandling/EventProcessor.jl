include("/home/gil/doomfish/doomfishjl/scripting/LogicHandler.jl")
include("inputtypes/Input.jl")
include("QueuedEvent.jl")


# This structure has been simplified significantly. What the EventProcessor now
# does is map inputs to events and events to callbacks, and tell the LogicHandler what
# events to invoke based on the gamestate, and the order in which to invoke them.
# We no longer reference specific types of events or inputs anywhere. We'll let
# the LogicHandler (whatever it may be) deal w/ that. Events and Inputs being
# abstract types, and the LogicHandler being an interface, any number of varying
# structures can be built around this single EventProcessor.


struct EventProcessor

    inputMap::Dict{ Input, Event }
    inputQueue::Vector{ Input }

    registeredEvents::Dict{ Event, Function }
    enqueuedEvents::Vector{ QueuedEvent }

    # WARNING before I shrunk this significantly, we kept track of the last dispatched moment w/ a variable here.
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


function registerEvent!(ϵ::EventProcessor, event::Event, callback::Function; input::Union{Input, Nothing} = nothing)
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkArgument( ϵ.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !haskey( ϵ.registeredEvents, event ), "event $event already registered in EventProcessor.registeredEvents" ) )
    ϵ.registeredEvents[event] = callback
    if nothing != input
        ϵ.inputMap[input] = event
    end
end


function enqueueEvent!(ϵ::EventProcessor, event::Event)
    checkArgument( event in keys( ϵ.registeredEvents ) , "event $event not registered in EventProcessor.registeredEvents" )
    push!( ϵ.enqueuedEvents )
end


function dispatchEvents!(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    # betamax:
    # TODO I'm not sure the choreography is consistent yet of making sure you get events
    # in a well defined order, which I care about because of rewing/replay, particularly the first moment#0 event

    # We're now using a sort of naive priority queue, so this may no longer be an issue

    while !(ϵ.enqueuedEvents |> isEmpty)
        dispatchEnqueuedEvents!( ϵ, logicHandler )
    end
    propagate( logicHandler )
end


function propagate(logicHandler::L) where L <: LogicHandler
    propagationStats =  @timed onEvent( logicHandler, GlobalEvent( PROPAGATE ) )
    updateStats!( metrics, HANDLE_PROGPAGATION_EVENT, propagationStats )
end


function dispatchEnqueuedEvents!(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    sort!( ϵ.enqueuedEvents )
    while !(ϵ.enqueuedEvents |> isEmpty)
        # we use the push! / popfirst! (1st element first, 2nd element second, etc) style queue
        # so that when we sort it by priority we don't have to reverse the sort order
        dispatchedEvent = popfirst!(ϵ.enqueuedEvents).event
        dispatchSingleEvent( ϵ, logicHandler, dispatchedEvent )
    end
end


function dispatchSingleEvent(ϵ::EventProcessor, logicHandler::L, event::Event) where L <: LogicHandler
    handleSingleEventStats = @timed onEvent( logicHandler, event )
    updateStats!( metrics, HANDLE_SINGLE_EVENT, handleSingleEventStats )
end
