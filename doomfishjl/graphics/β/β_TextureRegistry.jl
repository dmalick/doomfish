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

textureRegistry::Dict{TextureName, Texture}

LOCK_advisor::ReentrantLock
textureLoadAdvisor::Union{TextureLoadAdvisor, Nothing}

loadingThreadRunning::Bool

ramUnloadQueue::Vector{Texture}
texturePreloadAdvisingStats::Vector{Tuple{5}}


function getTexture(textureName::TextureName)
    texture = simpleTexture(textureName, false)
    checkState( !haskey( textureRegistry, textureName ), "textureRegistry already contains texture $textureName" )
    textureRegistry[textureName] = texture
    return texture
end


function checkAllSpritesReadyToRender(sprites::Vector{Sprite}, waitTime_ms::Int)
    deadline::Int128 = time_ms + waitTime_ms
    # not sure the below is properly translated
    missingTextures = Set( [ getTextureName(sprite, 0) for sprite in sprites ] )
    while time_ns/(10^6) < deadline && sizeof( missingTextures ) > 0
        # missingTexturesCopy = [ textureName for textureName in missingTextures ]
        #  for textureName in missingTexturesCopy
        #     if isCurrentlyLoaded(textureName) pop!( missingTextures, texture ) end
        # end
        # WARNING: pretty sure the filter below will do the job safely, but not positive
        filter!(name->!isCurrentlyLoaded(name), missingTextures)
        sleep( CHECK_READY_SLEEPTIME )
    end
    return sizeof( missingTextures ) == 0
end


function setAdvisor(advisor::TextureLoadAdvisor)
    lock( LOCK_advisor )
    textureLoadAdvisor = advisor
    unlock( LOCK_advisor )
end



# WARNING: I'm just guessing here
function startLoadingThread()
    @debug "started loading thread"
    Threads.@spawn begin
        while loadingThreadRunning
            texturesToLoad = getNeededTextures()
            if sizeof( texturesToLoad ) == 0
                sleep( LOADING_THREAD_SLEEPTIME )
            else
                @info "Loading $( sizeof(texturesToLoad) ) textures in background: $texturesToLoad"
                for texture in texturesToLoad loadTextureImage(texture) end
            end
        end
    end
    for StatsTuple in texturePreloadAdvisingStats
        updateStats!(metrics, TEXTURE_PRELOAD_ADVISING, StatsTuple)
    end
end


function getNeededTextures()::Vector{TextureName}
    lock( LOCK_advisor )
    textures = neededTextures()
    unlock( LOCK_advisor )
    return textures
end
# WARNING: the below function is a helper for getNeededTextures, and should never be called in other code.
# this is one of those times java might be helpful
function neededTextures() ::Vector{TextureName}
    texturePreloadAdvisingStats = @timed begin
        if nothing == textureLoadAdvisor return Vector{TextureName}() end
        # TODO: we'll have to pay careful attention to overloading getMostNeededTextures
        mostNeededTextures = [ textureName for textureName in getMostNeededTextures( textureLoadAdvisor, texturePreloadFrameLookahead )
                               if !isCurrentlyLoaded( textureRegistry, textureName ) ]
    end
    push!( texturePreloadAdvisingStats, texturePreloadAdvisingStats )
    return length( mostNeededTextures ) > texturePreloadFrameLookahead ?
           mostNeededTextures[ 1:texturePreloadFrameLookahead ] : mostNeededTextures
end



function isCurrentlyLoaded(textureName::TextureName) ::Bool
    try texture = textureRegistry[textureName]
    catch e
        e isa KeyError ? throw( ArgumentError("no such texture: $textureName") ) : throw(e)
    return getRamLoaded(texture)
end


function loadTextureImage(textureName::TextureName)
    texture = textureRegistry[textureName]
    checkState( nothing != texture )
    return setRamLoaded(texture, true)
end


function afterRender(memoryStrategy::MemoryStrategy, texture::Texture)
    afterRender(memoryStrategy, texture)
end


function queueForRamUnload(texture::Texture)
    push!(ramUnloadQueue, texture)
end


function processRamUnloadQueue()
    for texture in ramUnloadQueue
        setRamLoaded( pop!( ramUnloadQueue ), false )
    end
end
