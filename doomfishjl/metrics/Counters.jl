

mutable struct Counters
    ramImageBytesCounter::Int
    ramTexturesCounter::Int
    
    ramMeshBytesCounter::Int
    ramMeshesCounter::Int

    loadedSpriteTemplateCounter::Int
    virtualTexturesCounter::Int

    vramTexturesCounter::Int
    vramImageBytesCounter::Int

    jitMouseTextureLoadsCounter::Int

    rendertimeUploadsCounter::Int

    texturePreloadAdvisingTimer::Int

    # GlProgramBase
    skippedFramesByLogicCounter::Int
    skippedFramesByRenderCounter::Int

end
Counters() = return Counters( zeros( Int, length(Counters |> fieldnames), 1 )...)
