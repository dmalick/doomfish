include("/home/gil/doomfish/doomfishjl/sprite/SpriteRegistry.jl") # includes LogicHandler, FrameClock
include("Event.jl")


struct EventProcessor

    clock::FrameClock
    spriteRegistry::SpriteRegistry
    enqueuedEvents::Vector{Event}

    # we track the last dispatched moment so that if logic is paused, the same frame can be processed many times
    # but moment events get dispatched just once
    lastDispatchedMoment::Int
    alreadyBegun::Bool # = false
    acceptingCallbacks::Bool # = false

    EventProcessor(spriteRegistry::SpriteRegistry, frameClock::FrameClock) = new( frameClock, spriteRegistry,
                                                                                  Vector{Event}(), 1, false, false )
end


function dispatchEvents!(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    # betamax:
    # TODO I'm not sure the choreography is consistent yet of making sure you get events
    # in a well defined order, which I care about because of rewing/replay, particularly the first moment#0 event
    dispatchSpriteMomentEvents( ϵ.spriteRegistry, logicHandler )
    dispatchBeginEvent( ϵ, logicHandler )
    while !(ϵ.enqueuedSpriteEvents |> isEmpty)
        dispatchEnqueuedEvents!( ϵ, logicHandler )
    end
end


function dispatchBeginEvent(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    if ! ϵ.alreadyBegun
        ϵ.alreadyBegun = true
        onBegin(logicHandler)
        resetLogicFrames(ϵ.clock)
    end
end


# XXX: I kinda feel like the below might be a shitty way to do this, considering many
# if not most of these generated moment events correspond to no actual event.
# may eventually want to replace that w/ something more slick
function dispatchSpriteMomentEvents(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    if ϵ.lastDispatchedMoment == ϵ.clock.currentFrame
        # betamax:
        # we first generate the events then process them, because otherwise
        # if a script creates or destroys a sprite, orderedSprites will be modified
        # while we are iterating over orderedSprites, resulting in a ConcurrentModificationException
        # ...ask me how i know
        generatedEvents = [ SpriteEvent( SPRITE_MOMENT, sprite.name, getCurrentFrame(sprite), nothing )
                            for sprite in getSpritesInRenderOrder(ϵ.spriteRegistry) ]
        dispatchSingleSpriteEvent.( ϵ.spriteRegistry, logicHandler, generatedEvents )
    end
    spriteRegistry.lastDispatchedMoment = getCurrentFrame(frameClock)
end


function dispatchEnqueuedEvents!(ϵ::EventProcessor, logicHandler::L) where L <: LogicHandler
    while !(ϵ.enqueuedSpriteEvents |> isEmpty)
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


enqueueEvent!(ϵ::EventProcessor, event::Event) = pushfirst!( ϵ.enqueuedEvents, event )


# sprite-specific calls that mostly call methods from SpriteRegistry.jl


# this should only be called from script handlers, or else a duplicate moment 0 event may be dispatched on the
# first loop of a sprite created by the outer program
# this should also not be called before the BEGIN event is processed or moment events would happen early
# again, leave that to scripts
function createSprite(ϵ::EventProcessor, templateName::String, spriteName::SpriteName) :: Sprite
    createSprite!( ϵ.spriteRegistry, ϵ.clock, templateName, spriteName )
    # dispatchSpriteMomentEvents will only catch sprites that already existed before this frame and the frame
    # will then increment, so without this we'd miss the first sprite moment 0 event
    enqueueEvent( ϵ, SpriteEvent( SPRITE_CREATE, spriteName, nothing, nothing ) )
end

loadSpriteTemplate(ϵ::EventProcessor, templateName::String) = loadTemplate(ϵ.spriteRegistry, templateName)

getSpriteTemplate(ϵ::EventProcessor, templateName::String) = getTemplate(ϵ.spriteRegistry.spriteTemplateRegistry, templateName)

addSprite(ϵ::EventProcessor, sprite::Sprite) = addSprite!( ϵ.spriteRegistry, sprite )

function restoreSnapshot(ϵ::EventProcessor, spriteSnapshots::Vector{SpriteSnapshot})
    for snapshot in spriteSnapshots
        addTemplate!( ϵ.spriteRegistry.spriteTemplateRegistry, snapshot.templateName )
        sprite = createFromSnapshot( snapshot, ϵ.clock )
        addSprite( ϵ, sprite )
    end
    # Dom: XXX this is disgusting, are you serious?
    ϵ.alreadyBegun = true
end


spriteExists(ϵ::EventProcessor, spriteName::SpriteName) = spriteExists( ϵ.spriteRegistry, spriteName )

getSpriteByName(ϵ::EventProcessor, spriteName::SpriteName) = getSpriteByName( ϵ.spriteRegistry, spriteName )

getNamedSpriteMoment(ϵ::EventProcessor, templateName::String, momentName::String) = getNamedMoment(ϵ.spriteRegistry, templateName::String, momentName::String)

destroySprite(ϵ::EventProcessor, sprite::Sprite) = destroySprite!( ϵ.spriteRegistry, sprite )

close(ϵ::EventProcessor) = close(ϵ.spriteRegistry)
