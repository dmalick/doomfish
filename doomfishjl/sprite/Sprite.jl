include("includepath.jl")
includepath("pseudointerface/interface.jl")
includepath("doomfishjl/assetnames.jl")
includepath("doomfishjl/engine/FrameClock.jl")
includepath("doomfishjl/graphics/SpriteTemplate.jl")


@interface Sprite begin
    template::SpriteTemplate
    name::SpriteName
    frameClock::FrameClock
    creationSerial::Int
end

@abstractMethod( Sprite, close )
@abstractMethod( Sprite, toSnapshot )
# TODO: sound
# @abstractMethod( Sprite, getSoundPauseLevel )
# @abstractMethod( Sprite, getSoundRemarks )
# @abstractMethod( Sprite, getSoundDrift )
# @abstractMethod( Sprite, resyncSound )


function createSprite(spriteTemplate::SpriteTemplate, name::SpriteName, frameClock::FrameClock, SpriteImplementation::Type{S}) where S <: Sprite
    return SpriteImplementation(spriteTemplate, name, frameClock)
end


function createFromSnapshot(snapshot::GameplaySnapshot, frameClock::FrameClock, spriteImplementation::Type{S})::S where S <: Sprite
    SpriteImplementation( snapshot, frameClock )
end
