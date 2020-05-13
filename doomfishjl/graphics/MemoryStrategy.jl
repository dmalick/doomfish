includepath("doomfishjl/globalvars.jl")
include("Texture.jl")


@enum MemoryStrategy begin
    RESIDENT
    MANAGED
    STREAMING
end


function afterRender(memoryStrategy::MemoryStrategy, texture::Texture)
    if memoryStrategy == RESIDENT return end
    if memoryStrategy == MANAGED return end # FIXME: give this to TextureRegistry to manage
    if memoryStrategy == STREAMING
        setVramLoaded( texture, false )
        queueForRamUnload(texture)
    end
end


function chooseMemoryStrategy(size::Int) :: MemoryStrategy
    if size > textureMaxFramesForResidentMemoryStrategy
        return STREAMING
    else
        return RESIDENT
    end
end
