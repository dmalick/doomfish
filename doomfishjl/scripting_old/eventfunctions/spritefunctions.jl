include("/home/gil/doomfish/doomfishjl/sprite/SpriteRegistry.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/AbstractEventProcessor.jl")


# sprite-specific calls requiring access to both the SpriteRegistry and the EventProcessor


# this should only be called from script handlers, or else a duplicate moment 0 event may be dispatched on the
# first loop of a sprite created by the outer program
# this should also not be called before the BEGIN event is processed or moment events would happen early
# again, leave that to scripts
function createSprite(ϵ::EventProcessor, spriteRegistry::SpriteRegistry, clock::FrameClock, templateName::String, spriteName::SpriteName) :: Sprite
    createSprite!( spriteRegistry, clock, templateName, spriteName )
    # dispatchSpriteMomentEvents will only catch sprites that already existed before this frame and the frame
    # will then increment, so without this we'd miss the first sprite moment 0 event
    enqueueEvent!( ϵ, SpriteEvent( SPRITE_CREATE, spriteName, nothing, nothing ) )
end


function restoreSnapshot(ϵ::EventProcessor, spriteRegistry::SpriteRegistry, spriteSnapshots::Vector{SpriteSnapshot}, clock::FrameClock)
    for snapshot in spriteSnapshots
        addTemplate!( spriteRegistry.spriteTemplateRegistry, snapshot.templateName )
        sprite = createFromSnapshot( snapshot, clock )
        addSprite( ϵ, sprite )
    end
    # Dom: XXX this is disgusting, are you serious?
    # TODO: he's right, get rid of it
    ϵ.alreadyBegun = true
end


function destroySprite(ϵ::EventProcessor, spriteRegistry::SpriteRegistry, sprite::Sprite)
    destroySprite!( spriteRegistry, sprite )
    enqueueEvent!( ϵ, SpriteEvent( SPRITE_DESTROY, spriteName, nothing, nothing ) )
end
