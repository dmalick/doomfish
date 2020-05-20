include("/home/gil/doomfish/doomfishjl/scripting/LogicHandler.jl")
include("/home/gil/doomfish/doomfishjl/sprite/SpriteRegistry.jl") # includes FrameClock
include("inputtypes/Input.jl")
include("eventtypes/Event.jl")


# XXX I'm really not sure why we dispatch sprite moment events first before dispatching
# other enqueued events.


struct EventProcessor

    clock::FrameClock
    spriteRegistry::SpriteRegistry

    registeredEvents::Dict{Event, Function}
    enqueuedEvents::Vector{Event}

    inputMap::Dict{Input, Event}
    inputQueue::Vector{Input}

    # we track the last dispatched moment so that if logic is paused, the same frame can be processed many times
    # but moment events get dispatched just once
    lastDispatchedMoment::Int
    alreadyBegun::Bool # = false
    acceptingRegistrations::Bool # = false

    EventProcessor(spriteRegistry::SpriteRegistry, frameClock::FrameClock) = new( frameClock, spriteRegistry,
        Dict{Event, Function}(), Vector{Event}(), Dict{Input, Event}(), Vector{Input}(), 0, false, false )
end


enqueueInput!(ϵ::EventProcessor, input::Input) = haskey(ϵ.registeredEvents) ? pushfirst!( ϵ.inputQueue, input ) : return


function processInputs!(ϵ::EventProcessor)
    while !(ϵ.inputQueue |> isempty)
        # we use the pushfirst! / pop! style queue to be consistent w/ the event queue
        enqueueEvent!( ϵ, ϵ.inputMap[ pop!(p.inputQueue) ] )
    end
end


function registerEvent!(ϵ::EventProcessor, event::Event, callback::Function; input::Union{Input, Nothing} = nothing)
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkArgument( ϵ.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !haskey(ϵ.registeredEvents, event), "event $event already registered in EventProcessor.registeredEvents" ) )
    ϵ.registeredEvents[event] = callback
    if nothing != input
        ϵ.inputMap[input] = event
    end
end


function enqueueEvent!(ϵ::EventProcessor, event::Event)
    checkArgument( event in keys( ϵ.registeredEvents ) , "event $event not registered in EventProcessor.registeredEvents" )
    pushfirst!( ϵ.enqueuedEvents, event )
end


function dispatchEvents!(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    # betamax:
    # TODO I'm not sure the choreography is consistent yet of making sure you get events
    # in a well defined order, which I care about because of rewing/replay, particularly the first moment#0 event
    # XXX I'M not sure doing these separately is the right way to go at all.
    # I suppose it's possible queueing events by type is safer.

    # FIXME: I now think the way to go is to rig a priority queue-like thing by sort()ing / filter()ing events
    # out of the event queue by type, depending on what order we want specific events to resolve in.

    dispatchSpriteMomentEvents( ϵ.spriteRegistry, logicHandler )
    dispatchBeginEvent( ϵ, logicHandler )
    while !(ϵ.enqueuedEvents |> isEmpty)
        dispatchEnqueuedEvents!( ϵ, logicHandler )
    end
    propagate( ϵ, logicHandler )
end


function dispatchBeginEvent(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    if ! ϵ.alreadyBegun
        ϵ.alreadyBegun = true
        onBegin(logicHandler)
        resetLogicFrames(ϵ.clock)
    end
end


function propagate(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    propagationStats =  @timed onEvent( logicHandler, GlobalEvent( PROPAGATE ) )
    updateStats!( metrics, HANDLE_PROGPAGATION_EVENT, propagationStats )
end


function dispatchSpriteMomentEvents(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    if ϵ.lastDispatchedMoment == ϵ.clock.currentFrame
        # betamax:
        # we first generate the events then process them, because otherwise
        # if a script creates or destroys a sprite, orderedSprites will be modified
        # while we are iterating over orderedSprites, resulting in a ConcurrentModificationException
        # ...ask me how i know
        spriteMomentEvents = filter( event-> event.eventType == SPRITE_MOMENT, keys( ϵ.registeredEvents ) )
        dispatchSingleSpriteEvent.( ϵ.spriteRegistry, logicHandler, spriteMomentEvents )
    end
    spriteRegistry.lastDispatchedMoment = getCurrentFrame(frameClock)
end


function dispatchSingleSpriteEvent(ϵ::EventProcessor, logicHandler::L, event::SpriteEvent) where L <: LogicHandler
    if spriteExists( ϵ.spriteRegistry, event.name ) || event.eventType == SPRITE_DESTROY
        handleSingleEventStats = @timed onEvent( logicHandler, event )
        updateStats!( metrics, HANDLE_SINGLE_EVENT, handleSingleEventStats )
        enqueueEvent!( ϵ, logicHandler, event )
    end
end


function dispatchEnqueuedEvents!(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    while !(ϵ.enqueuedEvents |> isEmpty)
        # we use the pushfirst! / pop! (last element first, 2nd-to-last element second, etc) style queue
        # so that when we sort it by priority we don't have to reverse the sort order
        dispatchSingleEvent( ϵ, logicHandler, pop!(ϵ.enqueuedEvents) )

    end
end


function dispatchSingleEvent(ϵ::EventProcessor, logicHandler::L, event::Event) where L <: LogicHandler
    if event isa SpriteEvent
        dispatchSingleSpriteEvent( ϵ.spriteRegistry, logicHandler, event )
    else
        handleSingleEventStats = @timed onEvent( logicHandler, event )
        updateStats!( metrics, HANDLE_SINGLE_EVENT, handleSingleEventStats )
    end
end
