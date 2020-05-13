#using Logging

includepath("doomfishjl/imageio/SpriteTemplateManifest.jl")
includepath("doomfishjl/graphics/Texture.jl")
includepath("doomfishjl/graphics/TextureRegistry.jl")
includepath("doomfishjl/graphics/MemoryStrategy.jl")

# betamax: FIXME this class is getting unweildy, break it up
# no shit

mutable struct SpriteTemplate
    textures::Vector{Texture}
    # SoundName::Union{SoundName, Nothing}  # TODO: sound
    # SoundBuffer::Union{SoundName, Nothing}
    textureCount::Int
    nextCreationSerial::Int
    templateName::String
    frameCount::Int
    memoryStrategy::MemoryStrategy
    textureRegistry::TextureRegistry
end
function SpriteTemplate(manifest::SpriteTemplateManifest, textureRegistry::TextureRegistry)
    templateName = manifest.templateName
    textures = [ getTexture!( textureRegistry, textureName ) for textureName in manifest.textureNames ]
    textureCount = sizeof( textures )
    # soundName = manifest.soundName [or] getSoundName(manifest), [etc]
    memoryStrategy = chooseMemoryStrategy( sizeof(textures) )
    frameCount = sizeof( manifest.textureNames )
    @debug "Constructed $frameCount--frame SpriteTemplate $templateName"
    return SpriteTemplate( textures, textureCount, 0, templateName, frameCount, memoryStrategy, textureRegistry )
end


includepath("doomfishjl/engine/GameplaySnapshot.jl")


# public void loadSoundBuffer(SoundRegistry soundRegistry) {  TODO: sound
#     if(soundBuffer.isPresent() || !soundName.isPresent()) return;
#     soundBuffer = Optional.of(soundRegistry.getSoundBuffer(soundName.get()));
# }


function renderTemplate(spriteTemplate::SpriteTemplate, whichFrame::Int, location::TextureCoordinate, shaderProgram::ShaderProgram)
    texture = textures[ whichFrame ]

    textureRenderStats = @timed render( texture, location, shaderProgram )
    updateTimedStats!( metrics, TEXTURE_RENDERING, textureRenderingStats )

    textureAfterRenderStats = @timed afterRender( spriteTemplate.textureRegistry, spriteTemplate.memoryStrategy, texture )
    updateTimedStats!( metrics, TEXTURE_AFTER_RENDER )
end


function uploadTexture(spriteTemplate::SpriteTemplate, whichFrame::Int)
    texture = spriteTemplate.textures[whichFrame]
    setVramLoaded!(texture, true)
end


function close(spriteTemplate::SpriteTemplate)
    for texture in spriteTemplate.textures close(texture) end
end
