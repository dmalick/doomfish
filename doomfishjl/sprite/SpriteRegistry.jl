include("/home/gil/doomfish/doomfishjl/engine/FrameClock.jl")
include("/home/gil/doomfish/doomfishjl/graphics/SpriteTemplateRegistry.jl")
include("/home/gil/doomfish/doomfishjl/sprite/implementations/DefaultSpriteImpl.jl")
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("Sprite.jl")


struct SpriteRegistry
    registeredSprites::Dict{SpriteName, Sprite}
    spriteTemplateRegistry::SpriteTemplateRegistry

    SpriteRegistry(spriteTemplateRegistry) = new( Dict{SpriteName, Sprite}(), spriteTemplateRegistry )
end


function createSprite!(σ::SpriteRegistry, frameClock::FrameClock, templateName::String, spriteName::SpriteName, implementation::Type{S}) where S <: Sprite
    @debug "Creating $spriteName from template $templateName"

    sprite = createSprite( getTemplate( σ.spriteTemplateRegistry, templateName ), spriteName, frameClock, implementation )
    addSprite!(σ, sprite)

    return sprite
end


createSprite!(σ::SpriteRegistry, frameClock::FrameClock, templateName::String, spriteName::SpriteName) = createSprite!( σ, frameClock, templateName, spriteName, DefaultSpriteImpl )


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
end


function getSpritesInRenderOrder(σ::SpriteRegistry) :: Vector{Sprite}
    # the below sort should be sufficient to replace the java's Ordering objects
    return sort( σ.registeredSprites |> values, lt = (a,b)-> (a.layer <= b.layer && a.creationSerial < b.creationSerial) )
end


# FIXME: if it turns out the revese() call below messes up performance, replace it
getSpritesInReverseRenderOrder(σ::SpriteRegistry) = reverse( getSpritesInRenderOrder(σ) )


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
