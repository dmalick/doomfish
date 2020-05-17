basepath = "/home/gil/.atom/doomfishjl/"
include(basepath*"sprite/SpriteRegistry.jl")
include("LogicHandler.jl")



struct EventProcessor
    spriteRegistry::SpriteRegistry
    globalFrameClock::FrameClock

    enqueuedEvents::Vector{E} where E <: Event

    lastDispatchedMoment::Union{Int, Nothing}
    acceptingCallbacks::Bool # = false
    alreadyBegun::Bool # = false

    EventProcessor(eventProcessor::EventProcessor) = new( FrameClock(), eventProcessor.spriteRegistry, Vector{E}(), nothing, false, false ) where E <: Event
end



function dispatchEvents(eventProcessor::EventProcessor, eventProcessor::EventProcessor, logicHandler::L) where L <: LogicHandler
    # betamax:
    # TODO I'm not sure the choreography is consistent yet of making sure you get events
    # in a well defined order, which I care about because of rewing/replay, particularly the first moment#0 event
    dispatchSpriteMomentEvents( eventProcessor.spriteRegistry, logicHandler )
    dispatchBeginEvent( eventProcessor.spriteRegistry, logicHandler )
    while ! eventProcessor.enqueuedEvents |> isEmpty
        dispatchEnqueuedEvents!( event, logicHandler )
    end
end


function dispatchSingleEvent(eventProcessor::EventProcessor, logicHandler::L, event::E) where L <: LogicHandler where E <: Event
    handleSingleEventStats = @timed onEvent( logicHandler, event )
    updateStats!( metrics, HANDLE_SINGLE_EVENT, handleSingleEventStats )
end


function dispatchSingleSpriteEvent(eventProcessor::EventProcessor, logicHandler::L, event::SpriteEvent) where L <: LogicHandler
    if spriteExists( eventProcessor.spriteRegistry, event.name ) || event.eventType == SPRITE_DESTROY
        dispatchSingleEvent( eventProcessor, logicHandler, event )
    end
end


function dispatchGlobalEvents(eventProcessor::EventProcessor, logicHandler::L) where L <: LogicHandler
    dispatchBeginEvent(eventProcessor.spriteRegistry, logicHandler)

end


function dispatchBeginEvent(eventProcessor::EventProcessor, logicHandler::L) where L <: LogicHandler
    if ! eventProcessor.spriteRegistry.alreadyBegun
        eventProcessor.spriteRegistry.alreadyBegun = true
        onBegin(logicHandler)
        resetLogicFrames(eventProcessor.spriteRegistry.frameClock)
    end
end


function dispatchGlobalKeyEvents(eventProcessor::EventProcessor, logicHandler::L) where L <: LogicHandler

end


function dispatchSpriteMomentEvents(eventProcessor::EventProcessor, logicHandler::L) where L <: LogicHandler
    if eventProcessor.eventProcessor.spriteRegistry.lastDispatchedMoment == eventProcessor.spriteRegistry.frameClock.currentFrame
        # betamax:
        # we first generate the events then process them, because otherwise
        # if a script creates or destroys a sprite, orderedSprites will be modified
        # while we are iterating over orderedSprites, resulting in a ConcurrentModificationException
        # ...ask me how i know
        generatedEvents = Vector{SpriteEvent}()
        for sprite in getSpritesInRenderOrder(eventProcessor.spriteRegistry)
            momentEvent = SpriteEvent( SPRITE_MOMENT, sprite.name, getCurrentFrame(sprite), nothing )
            push!( generatedEvents, momentEvent )
        end
        for event in generatedEvents
            dispatchSingleSpriteEvent( eventProcessor.spriteRegistry, logicHandler, event )
        end
    end
    eventProcessor.spriteRegistry.lastDispatchedMoment = getCurrentFrame(eventProcessor.spriteRegistry.frameClock)
end


function dispatchEnqueuedSpriteEvents!(eventProcessor::EventProcessor, logicHandler::L) where L <: LogicHandler
    while !eventProcessor.spriteRegistry.enqueuedSpriteEvents |> isEmpty
        dispatchSingleSpriteEvent( eventProcessor.spriteRegistry, logicHandler, pop!( eventProcessor.spriteRegistry.enqueuedSpriteEvents ) )
    end
end


function dispatchSingleSpriteEvent(eventProcessor::EventProcessor, logicHandler::L, event::SpriteEvent) where L <: LogicHandler
    if spriteExists( eventProcessor.spriteRegistry, event.name ) || event.eventType == SPRITE_DESTROY
        handleSingleEventStats = @timed onSpriteEvent( logicHandler, event )
        updateStats!( metrics, HANDLE_SINGLE_EVENT, handleSingleEventStats )
    end
end
