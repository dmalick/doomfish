include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")


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


function destroySprite(ϵ::EventProcessor, sprite::Sprite)
    destroySprite!( ϵ.spriteRegistry, sprite )
    enqueueEvent!( ϵ, SpriteEvent( SPRITE_DESTROY, spriteName, nothing, nothing ) )
end
