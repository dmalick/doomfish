include("includepath.jl")
includepath("doomfishjl/assetnames.jl")
includepath("doomfishjl/engine/FrameClock.jl")
includepath("doomfishjl/graphics/SpriteTemplateRegistry.jl")
includepath("doomfishjl/sprite/SpriteEvent.jl")
includepath("doomfishjl/sprite/implementations/SpriteImpl.jl")
includepath("doomfishjl/sprite/Sprite.jl")
include("LogicHandler.jl")


struct SpriteRegistry
    frameClock::FrameClock
    #
    registeredSprites::Dict{SpriteName, Sprite}
    enqueuedSpriteEvents::Vector{SpriteEvent}
    #
    # # betamax:
    # # private static final Ordering<Sprite> CREATION_ORDERING = Ordering.natural().onResultOf(Sprite::getCreationSerial);
    # # private static final Ordering<Sprite> LAYER_ORDERING = Ordering.natural().onResultOf(Sprite::getLayer);
    # # private static final Ordering<Sprite> RENDER_ORDERING = LAYER_ORDERING.compound(CREATION_ORDERING);
    # # private final Ordering<SpriteName> NAME_RENDER_ORDERING = RENDER_ORDERING.onResultOf(this::getSpriteByName);
    #
    spriteTemplateRegistry::SpriteTemplateRegistry

    # we track the last dispatched moment so that if logic is paused, the same frame can be processed many times
    # but moment events get dispatched just once
    lastDispatchedMoment::Int
    alreadyBegun::Bool # = false
    acceptingCallbacks::Bool # = false
    function SpriteRegistry(frameClock, spriteTemplateRegistry)
        return new( frameClock, Dict{SpriteName, Sprite}(), Vector{SpriteEvent}(), spriteTemplateRegistry, 1, false, false )
    end
end

# this should only be called from script handlers, or else a duplicate moment#0 event may be dispatched on the
# first loop of a sprite created by the outer program
# this should also not be called before the BEGIN event is processed or moment events would happen early
# again, leave that to scripts
function createSprite!(spriteRegistry::SpriteRegistry, templateName::String, spriteName::SpriteName) :: Sprite
    @debug "Creating $spriteName from template $templateName"

    sprite = create( getTemplate( spriteRegistry.spriteTemplateRegistry, templateName ), spriteRegistry.frameClock )
    addSprite!(spriteRegistry, sprite)

    # dispatchSpriteMomentEvents will only catch sprites that already existed before this frame and the frame
    # will then increment, so without this we'd miss the first sprite moment#0 event
    enqueueSpriteEvent( SpriteEvent( SPRITE_CREATE, spriteName, nothing, nothing ) )
    return sprite
end


function addSprite!(spriteRegistry::SpriteRegistry, sprite::Sprite)
    name = sprite.name
    checkArgument( !haskey( spriteRegistry.registeredSprites, name ), "duplicate sprite name: $name" )
    spriteRegistry.registeredSprites[name] = sprite
end


function restoreSnapshot!(spriteRegistry::SpriteRegistry, spriteSnapshots::Vector{SpriteSnapshot})
    for snapshot in spriteSnapshots
        template = getTemplate( spriteRegistry.spriteTemplateRegistry, snapshot.templateName )
        sprite = createFromSnapshot( snapshot, spriteRegistry.frameClock )
        addSprite!( spriteRegistry, sprite )
    end
    # Dom: XXX this is disgusting, are you serious?
    spriteRegistry.alreadyBegun = true
end


function getSpriteByName(registry::SpriteRegistry, name::SpriteName)
    try sprite = registry.registeredSprites[name]
    catch e
        e isa KeyError ? throw( ArgumentError("No such sprite $name") ) : throw(e)
    end
    return sprite
end


function destroySprite!(spriteRegistry::SpriteRegistry, spriteName::SpriteName)
    @debug "Destroying $spriteName"
    checkState( haskey( spriteRegistry.registeredSpriteNames, spriteName ), "no such sprite: $spriteName" )
    sprite = spriteRegistry.registeredSprites[spriteName]
    close(sprite)
    pop!( spriteRegistry.registeredSprites, spriteName )
    enqueueSpriteEvent!( spriteRegistry, SpriteEvent( SPRITE_DESTROY, spriteName, nothing, nothing ) )
end


function getSpritesInRenderOrder(spriteRegistry::SpriteRegistry) :: Vector{Sprite}
    # the below sort should be sufficient to replace the java's Ordering objects
    return sort( spriteRegistry.registeredSprites |> values, lt = (a,b)-> (a.layer <= b.layer && a.creationSerial < b.creationSerial) )
end

# WARNING not sure whether the below reverse (the more readable way of doing it) will cost us on performance
getSpritesInReverseRenderOrder(spriteRegistry::SpriteRegistry) = reverse( getSpritesInRenderOrder(spriteRegistry) )


function dispatchEvents(spriteRegistry::SpriteRegistry, logicHandler::L) where L <: LogicHandler
    # betamax:
    # TODO I'm not sure the choreography is consistent yet of making sure you get events
    # in a well defined order, which I care about because of rewing/replay, particularly the first moment#0 event
    dispatchSpriteMomentEvents( spriteRegistry, logicHandler )
    dispatchBeginEvent( spriteRegistry, logicHandler )
    while ! spriteRegistry.enqueuedSpriteEvents |> isEmpty
        dispatchEnqueuedSpriteEvents!( spriteRegistry, logicHandler )
    end
end

function dispatchBeginEvent(spriteRegistry::SpriteRegistry, logicHandler::L) where L <: LogicHandler
    if ! spriteRegistry.alreadyBegun
        spriteRegistry.alreadyBegun = true
        onBegin(logicHandler)
        resetLogicFrames(spriteRegistry.frameClock)
    end
end


function dispatchGlobalKeyEvents(spriteRegistry::SpriteRegistry, logicHandler::L) where L <: LogicHandler

end


function dispatchSpriteMomentEvents(spriteRegistry::SpriteRegistry, logicHandler::L) where L <: LogicHandler
    if spriteRegistry.lastDispatchedMoment == spriteRegistry.frameClock.currentFrame
        # betamax:
        # we first generate the events then process them, because otherwise
        # if a script creates or destroys a sprite, orderedSprites will be modified
        # while we are iterating over orderedSprites, resulting in a ConcurrentModificationException
        # ...ask me how i know
        generatedEvents = Vector{SpriteEvent}()
        for sprite in getSpritesInRenderOrder(spriteRegistry)
            momentEvent = SpriteEvent( SPRITE_MOMENT, sprite.name, getCurrentFrame(sprite), nothing )
            push!( generatedEvents, momentEvent )
        end
        for event in generatedEvents
            dispatchSingleSpriteEvent( spriteRegistry, logicHandler, event )
        end
    end
    spriteRegistry.lastDispatchedMoment = getCurrentFrame(frameClock)
end


function dispatchEnqueuedSpriteEvents!(spriteRegistry::SpriteRegistry, logicHandler::L) where L <: LogicHandler
    while !spriteRegistry.enqueuedSpriteEvents |> isEmpty
        dispatchSingleSpriteEvent( spriteRegistry, logicHandler, pop!( spriteRegistry.enqueuedSpriteEvents ) )
    end
end


function dispatchSingleSpriteEvent(spriteRegistry::SpriteRegistry, logicHandler::L, event::SpriteEvent) where L <: LogicHandler
    if spriteExists( spriteRegistry, event.name ) || event.eventType == SPRITE_DESTROY
        handleSingleEventStats = @timed onSpriteEvent( logicHandler, event )
        updateTimedStats!( metrics, HANDLE_SINGLE_EVENT, handleSingleEventStats )
    end
end


function enqueueSpriteEvent!(spriteRegistry::SpriteRegistry, spriteEvent::SpriteEvent)
    pushfirst!( spriteRegistry.enqueuedSpriteEvents, spriteEvent )
end


function spriteExists(spriteRegistry::SpriteRegistry, spriteName::SpriteName) :: Bool
    return haskey( spriteRegistry.registeredSprites, spriteName )
end


function loadTemplate(spriteRegistry::SpriteRegistry, templateName::String)
    getTemplate( spriteRegistry.spriteTemplateRegistry, templateName )
end


function close(spriteRegistry::SpriteRegistry)
    for sprite in values( spriteRegistry.registeredSprites )
        close( sprite )
    end
end


function getNamedMoment(spriteRegistry::SpriteRegistry, templateName::String, momentName::String) :: Int
    return getNamedMoment( spriteRegistry.spriteTemplateRegistry, templateName, momentName )
end
