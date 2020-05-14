
include("/home/gil/doomfish/doomfishjl/sprite/Sprite.jl")
include("/home/gil/doomfish/doomfishjl/sprite/Clickability.jl")
include("/home/gil/doomfish/doomfishjl/engine/FrameClock.jl")
include("/home/gil/doomfish/doomfishjl/engine/GameplaySnapshot.jl")
include("/home/gil/doomfish/doomfishjl/opengl/coordinates.jl")


# WARNING / TODO / whatever
# dom built this as an inner class of SpriteTemplate in betamax. this makes our job a particular
# pain in the ass.
# I'm not yet sure how to proceed.


struct SpriteImpl <: Sprite

    template::SpriteTemplate

    name::SpriteName
    frameClock::FrameClock

    creationSerial::Int
    initialFrame::Int

    clickability::Clickability # = TRANSPARENCY_BASED
    layer::Int # = 0
    repetitions::Int # = 0
    pinnedToCursor::Bool # = false
    paused::Bool # = false
    hidden ::Bool # = false
    pausedFrame::Int # = 0
    # soundSource::Union{SoundSource, Nothing}  # TODO sound
    position::TextureCoordinate # = 0.5, 0.5, dead center

    function SpriteImpl(template::SpriteTemplate, name::SpriteName, clock::FrameClock)
        initialFrame = clock.currentFrame
        creationSerial = (template.nextCreationSerial += 1)
        # soundSource = setupSound()  # TODO sound
        return new(template, textureRegistry, name, clock, creationSerial, initialFrame,
                   TRANSPARENCY_BASED, 0, 0, false, false, false, 0, #=soundSource,=# TextureCoordinate(0.5, 0.5))
    end
end


# TODO sound
# betamax:
# private Optional<SoundSource> setupSound() {
#     if(soundBuffer.isPresent()) {
#         LOG.debug("Playing sound for sprite {}", getName());
#         return Optional.of(soundBuffer.get().beginPlaying());
#     } else {
#         checkState(!soundName.isPresent(), "Sound was not loaded!");
#         return Optional.empty();
#     }
# }


function SpriteImpl(snapshot::SpriteSnapshot, frameClock::FrameClock)
    return SpriteImpl(snapshot.template,
                      snapshot.name,
                      snapshot.frameClock,
                      snapshot.creationSerial,
                      snapshot.initialFrame,
                      snapshot.clickability,
                      snapshot.layer,
                      snapshot.repetitions,
                      snapshot.pinnedToCursor,
                      setHidden(snapshot.hidden),
                      setPaused(snapshot.paused),
                      snapshot.pausedFrame,
                      # setupSound(snapshot.template),  TODO: sound
                      snapshot.position
                      )
end

function render(sprite::SpriteImpl, shaderProgram::ShaderProgram)
    if !sprite.hidden renderTemplate( sprite.template, getRenderedTexture(sprite), sprite.position, shaderProgram ) end
end


function getCurrentFrame(sprite::SpriteImpl) ::Int
    if sprite.paused
        return (sprite.pausedFrame - sprite.initialFrame) % getTotalFrames(sprite)
    else
        return ( getCurrentFrame(frameClock) - sprite.initialFrame ) % getTotalFrames(sprite)
    end
end


convert(String, sprite::SpriteImpl) = return "Sprite($(sprite.name))"


function isClickableAtCoordinate(sprite::SpriteImpl, coord::TextureCoordinate)
    if sprite.clickability == TRANSPARENCY_BASED
        return true
    elseif sprite.clickability == NOWHERE
        return false
    else
        texture = sprite.template.textures[ getRenderedTexture(sprite) ]
        translatedCoord = coord - position - TextureCoordinate(0.5, 0.5)
        transparentAtCoordinate = !isValidCoordinate( translatedCoord ) || isTransparentAtCoordinate( texture, translatedCoord )
        @info "isClickableAtCoordinate($sprite, $coord) == $(!transparentAtCoordinate)"
        return !transparentAtCoordinate
    end
end


function getRenderedTexture(sprite::SpriteImpl) :: Int
    return getCurrentFrame(sprite) % sprite.template.textureCount
end


function getTextureName(sprite::SpriteImpl, framesAhead::Int)
    return sprite.template.textures[ (getCurrentFrame(sprite) + framesAhead) % sprite.template.textureCount ].name
end


function setLayer!(sprite::SpriteImpl, layer::Int)
    @debug "setLayer( $sprite, $layer )"
    sprite.layer = layer
end


getTotalFrames(sprite)::Int = return sprite.template.textureCount * sprite.repetitions


function setRepetitions!(sprite::SpriteImpl, repetitions::Int)
    checkArgument( getAge(sprite) == 0, "Only can setRepetitions when sprite is first created" )
    checkArgument( sprite.repetitions > 0 )
    sprite.repetitions = repetitions
end


# accurate for sprites without sound and sprites with sound that never have setPaused(true)
# FIXME: have a initialCreationFrame, used for nothing but useful for general dev info
getAge(sprite::SpriteImpl) = return sprite.frameClock.currentFrame - sprite.initialFrame


function setPaused!(sprite::SpriteImpl, paused::Bool)
     if sprite.paused == paused return end
     if paused doPause!(sprite) end
     if !paused doUnpause!(sprite) end
     sprite.paused = paused
end


function doPause!(sprite)
    sprite.pausedFrame = sprite.frameClock.currentFrame
    # if nothing != sprite.soundSource pause(sprite.soundSource) end  TODO: sound
end


function doUnpause!(sprite)
    sprite.initialFrame += (sprite.frameClock.currentFrame) - sprite.pausedFrame
    sprite.pausedFrame = 0
    # if nothing != sprite.soundSource resume(sprite.soundSource) end  TODO: sound
end


function setHidden!(sprite::SpriteImpl, hidden::Bool)
    if sprite.hidden == hidden return end
    # if hidden && (nothing != sprite.soundSource) mute(sprite.soundSource) end  TODO: sound
    # if !hidden && (nothing != sprite.soundSource) unmute(sprite.soundSource) end
    sprite.hidden = hidden
end


function close(sprite::SpriteImpl)
    # if nothing != sprite.soundSource close(sprite.soundSource) end  TODO: sound
end


uploadCurrentFrame(sprite::SpriteImpl) = uploadTexture( getRenderedTexture(sprite) )


function getSoundPauseLevel(sprite::SpriteImpl) :: Int # TODO: sound
    # if nothing != sprite.soundSource
    #     return sprite.soundSource.pauseLevel
    # else
    #     return -1
    # end
end


function setPosition(sprite::SpriteImpl, position::TextureCoordinate)
    checkArgument( isValidCoordinate( position ), "Out of bounds position $position" )
    sprite.position = position
end


function getSoundRemarks(sprite::SpriteImpl) :: String
    # return (nothing != sprite.soundSource) ? getRemarks(sprite.soundSource) : "n/a"  TODO: sound
end


# TODO: sound
# betamax:
# @Override public float getSoundDrift() {
#     return soundSource.isPresent()
#             ? soundSource.get().getDrift(getExpectedSoundPositionInSeconds())
#             : 0.0f;
# }
#
# private float getExpectedSoundPositionInSeconds() {
#     int expectedPositionInFrames = frameClock.getCurrentFrame() - initialFrame;
#     checkState(expectedPositionInFrames >= 0, "Negative expected audio position (current frame %s, initial frame %s)", frameClock.getCurrentFrame(), initialFrame);
#     return (float)expectedPositionInFrames / (float) Global.targetFps;
# }
#
# @Override public void resyncSound() {
#     if(soundSource.isPresent()) {
#         soundSource.get().resync(getExpectedSoundPositionInSeconds());
#     }
# }


function toSnapshot(sprite::Sprite) :: SpriteSnapshot
    return SpriteSnapshot(  sprite.templateName,
                            sprite.name,
                            sprite.creationSerial,
                            sprite.initialFrame,
                            sprite.clickability,
                            sprite.layer,
                            sprite.repetitions,
                            sprite.pinnedToCursor,
                            sprite.paused,
                            sprite.hidden,
                            sprite.pausedFrame,
                            sprite.position
                         )
end
