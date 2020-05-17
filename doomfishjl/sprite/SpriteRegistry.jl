include("/home/gil/doomfish/doomfishjl/engine/FrameClock.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/LogicHandler.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/eventtypes/SpriteEvent.jl")
include("/home/gil/doomfish/doomfishjl/graphics/SpriteTemplateRegistry.jl")
include("/home/gil/doomfish/doomfishjl/sprite/implementations/SpriteImpl.jl")
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("Sprite.jl")


struct SpriteRegistry
    registeredSprites::Dict{SpriteName, Sprite}
    spriteTemplateRegistry::SpriteTemplateRegistry

    SpriteRegistry(spriteTemplateRegistry) = new( Dict{SpriteName, Sprite}(), spriteTemplateRegistry )
end


function createSprite!(σ::SpriteRegistry, frameClock::FrameClock, templateName::String, spriteName::SpriteName) :: Sprite
    @debug "Creating $spriteName from template $templateName"

    sprite = create( getTemplate( σ.spriteTemplateRegistry, templateName ), frameClock )
    addSprite!(σ, sprite)

    return sprite
end


function addSprite!(σ::SpriteRegistry, sprite::Sprite)
    name = sprite.name
    checkArgument( !haskey( σ.registeredSprites, name ), "duplicate sprite name: $name" )
    σ.registeredSprites[name] = sprite
end


function getSpriteByName(σ::SpriteRegistry, name::SpriteName)
    checkArgument( haskey(σ, name), "No such sprite $name" )
    return σ.registeredSprites[name]
end


function destroySprite!(σ::SpriteRegistry, spriteName::SpriteName)
    @debug "Destroying $spriteName"
    checkState( haskey( σ.registeredSpriteNames, spriteName ), "no such sprite: $spriteName" )
    sprite = σ.registeredSprites[spriteName]
    close(sprite)
    pop!( σ.registeredSprites, spriteName )
    enqueueSpriteEvent!( σ, SpriteEvent( SPRITE_DESTROY, spriteName, nothing, nothing ) )
end


function getSpritesInRenderOrder(σ::SpriteRegistry) :: Vector{Sprite}
    # the below sort should be sufficient to replace the java's Ordering objects
    return sort( σ.registeredSprites |> values, lt = (a,b)-> (a.layer <= b.layer && a.creationSerial < b.creationSerial) )
end


getSpritesInReverseRenderOrder(σ::SpriteRegistry) = reverse( getSpritesInRenderOrder(σ) )



function dispatchSingleSpriteEvent(σ::SpriteRegistry, logicHandler::L, event::SpriteEvent) where L <: LogicHandler
    if spriteExists( σ, event.name ) || event.eventType == SPRITE_DESTROY
        handleSingleEventStats = @timed onEvent( logicHandler, event )
        updateStats!( metrics, HANDLE_SINGLE_EVENT, handleSingleEventStats )
    end
end


function spriteExists(σ::SpriteRegistry, spriteName::SpriteName) :: Bool
    return haskey( σ.registeredSprites, spriteName )
end


function loadTemplate(σ::SpriteRegistry, templateName::String)
    getTemplate( σ.spriteTemplateRegistry, templateName )
end


function close(σ::SpriteRegistry)
    for sprite in values( σ.registeredSprites )
        close( sprite )
    end
end


function getNamedMoment(σ::SpriteRegistry, templateName::String, momentName::String) :: Int
    return getNamedMoment( σ.spriteTemplateRegistry, templateName, momentName )
end
