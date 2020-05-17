using Logging

include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/graphics/Texture.jl")
include("/home/gil/doomfish/doomfishjl/graphics/TextureLoadAdvisor.jl")
include("/home/gil/doomfish/doomfishjl/graphics/MemoryStrategy.jl")


CHECK_READY_SLEEPTIME = 0.004 # ms
LOADING_THREAD_SLEEPTIME = 0.004

# TODO: Julia multithreading may be a stumbling block here. There's no simple way to define a thread

#= betamax:
FIXME: Document this class
    Couple performance improvement that could be made:
    - we dumbly use a sort of wait/sleep loop to wait for loaded sprites in checkAllSpritesReadyToRender from
     main thread waiting for loader thread. we should instead wait to be notified by the loader thread
    - since loader thread actively calls TextureLoadAdvisor instead of TextureLoadAdvisor pushing changes once per
     frame, we also use a stupid ineffecient wait/sleep loop there, and loader thread should wait to be notified by
     main thread. that said it's nice the advisory work is mostly done in the loader thread, it can take a few dozen
     ms and should not hold up a render, so it should just be a notify once per frame
=#


# WARNING: much of this is guesswork
mutable struct TextureRegistry
    LOCK_advisor::ReentrantLock

    advisor::Union{TextureLoadAdvisor, Nothing}
    textures::Dict{TextureName, Texture}

    loadingThreadRunning::Bool

    ramUnloadQueue::Vector{Texture}
    texturePreloadAdvisingStats::Vector{Tuple{5}}
end
function TextureRegistry()
    textureRegistry = TextureRegistry( ReentrantLock(), nothing, Dict{TextureName, Texture}(), true, Vector{Texture}(), Vector{Tuple{5}}() )
    startLoadingThread(textureRegistry)
    return textureRegistry
end


function getTexture!(textureRegistry::TextureRegistry, textureName::TextureName)
    texture = simpleTexture(textureName, false)
    checkState( !haskey( textureRegistry.textures, textureName ), "TextureRegistry already contains texture $textureName" )
    textureRegistry.textures[textureName] = texture
    return texture
end


function checkAllSpritesReadyToRender(textureRegistry::TextureRegistry, waitTimeMs::Int)
    deadline::Int128 = time_ns/(10^6) + waitTimeMs
    # not sure the below is properly translated
    missingTextures = Set([ getTextureName(sprite, 0) for sprite in sprites ])
    while time_ns/(10^6) < deadline && sizeof( missingTextures ) > 0
        missingTexturesCopy = [texrureName for textureName in missingTextures]
         for textureName in missingTexturesCopy
            if isCurrentlyLoaded(textureName) pop!( missingTextures, texture ) end
        end
        sleep( CHECK_READY_SLEEPTIME )
    end
    return sizeof( missingTextures ) == 0
end


function setAdvisor!(textureRegistry::TextureRegistry, advisor::TextureLoadAdvisor)
    lock( textureRegistry.LOCK_advisor )
    textureRegistry.advisor = advisor
    unlock( textureRegistry.LOCK_advisor )
end



# WARNING: I'm just guessing here
function startLoadingThread(textureRegistry::TextureRegistry)
    @debug "started loading thread"
    Threads.@spawn begin
        while textureRegistry.loadingThreadRunning
            texturesToLoad = getNeededTextures!(textureRegistry)
            if sizeof( texturesToLoad ) == 0
                sleep( LOADING_THREAD_SLEEPTIME )
            else
                @info "Loading $( sizeof(texturesToLoad) ) textures in background: $texturesToLoad"
                for texture in texturesToLoad loadTextureImage(texture) end
            end
        end
    end
    for StatsTuple in textureRegistry.texturePreloadAdvisingStats
        updateStats!(metrics, TEXTURE_PRELOAD_ADVISING, StatsTuple)
    end
end


function getNeededTextures!(textureRegistry::TextureRegistry)::Vector{TextureName}
    lock( textureRegistry.LOCK_advisor )
    textures = neededTextures!(textureRegistry)
    unlock( textureRegistry.LOCK_advisor )
    return textures
end
# WARNING: the below function is a helper for getNeededTextures, and should never be called in other code.
# this is one of those times java might be helpful
function neededTextures!(textureRegistry::TextureRegistry) ::Vector{TextureName}
    texturePreloadAdvisingStats = @timed begin
        if nothing == textureRegistry.advisor return Vector{TextureName}() end
        # TODO: we'll have to pay careful attention to overloading getMostNeededTextures
        mostNeededTextures = [ textureName for textureName in getMostNeededTextures( advisor, texturePreloadFrameLookahead )
                               if !isCurrentlyLoaded( textureRegistry, textureName ) ]
    end
    push!( textureRegistry.texturePreloadAdvisingStats, texturePreloadAdvisingStats )
    return length( mostNeededTextures ) > texturePreloadFrameLookahead ?
           mostNeededTextures[ 1:texturePreloadFrameLookahead ] : mostNeededTextures
end



function isCurrentlyLoaded(textureRegistry::TextureRegistry, textureName::TextureName) ::Bool
    texture = textureRegistry.textures[textureName]
    checkState( nothing != texture )
    return getRamLoaded(texture)
end


function loadTextureImage(textureRegistry::TextureRegistry, textureName::TextureName)
    texture = textureRegistry.textures[textureName]
    checkState( nothing != texture )
    return setRamLoaded(texture, true)
end


function afterRender(textureRegistry::TextureRegistry, memoryStrategy::MemoryStrategy, texture::Texture)
    afterRender(memoryStrategy, texture)
end


function queueForRamUnload(textureRegistry::TextureRegistry, texture::Texture)
    push!(textureRegistry.ramUnloadQueue, texture)
end


function processRamUnloadQueue(textureRegistry::TextureRegistry)
    for texture in textureRegistry.ramUnloadQueue
        setRamLoaded( pop!( textureRegistry.ramUnloadQueue ), false )
    end
end
