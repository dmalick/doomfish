
include("/home/gil/doomfish/doomfishjl/globalvars.jl")

include("/home/gil/doomfish/doomfishjl/opengl/GlWindow.jl")

include("/home/gil/doomfish/doomfishjl/graphics/Texture.jl")
include("/home/gil/doomfish/doomfishjl/graphics/TextureRegistry.jl")
include("/home/gil/doomfish/doomfishjl/graphics/SpriteTemplateRegistry.jl")

include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")

include( resourcePathBase * "scripting.jl")

include("GlProgramBase.jl")
include("GameLoopFrameClock.jl")
include("TextureLoadAdvisorImpl.jl")


struct DoomfishGlProgram <: GlProgramBase
    mainWindow::GlWindow
    frameClock::GameLoopFrameClock
    # soundWorld::SoundWorld
    # soundRegistry::SoundRegistry
    textureRegistry::TextureRegistry
    spriteTemplateRegistry::SpriteTemplateRegistry
    # devConsole::DevConsole
    # soundSyncer::SoundSyncer
    # scriptWorld::ScriptWorld
    spriteRegistry::SpriteRegistry
    # highlightedSprite::Union{SpriteName, Nothing}
    eventProcessor::EventProcessor
    scriptWorld::ScriptWorld

    pausedTexture::Texture
    loadingTexture::Texture
    crashTexture::Texture
    crashed::Bool # = false
    loading::Bool # = false
end


# betamax:
# private BetamaxGlProgram() {
#     devConsole = getDebugMode() ? new DevConsole() : null;
# }
#
# public static void main(String[] args) {
#     new BetamaxGlProgram().run();
# }


function initialize()
    if mainScript == Nothing
        @error "No main logic script defined (-Dbetamax.mainScript), exiting"
        throw( ArgumentError("No main logic script defined") )
    end

    include("allshaders.jl")
    prepareForDrawing()
    prepareBuiltinTextures()

    # enable transparency
    glEnable( GL_BLEND )
    glEnable( GL_DEPTH_TEST )
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end


# betamax has showInitialLoadingScreen() defined here. I moved it to GlProgramBase.


function expensiveInitialize(program::DoomfishGlProgram)
    preloadTemplates( program.spriteTemplateRegistry )
    newWorld( program, resetSprites = true )
end


function prepareBuiltinTextures(program::DoomfishGlProgram)
    program.pausedTexture = simpleTexture( pausedTextureFile )
    program.crashTexture = simpleTexture( crashTextureFile )
    program.loadingTexture = simpleTexture( loadingTextureFile )
end


function newWorld(program::DoomfishGlProgram; resetSprites::Bool)
    @info "Starting new world"
    if program.crashed
        @warn "Restarting world after a crash. Unpredictable behavior could occur! (but maybe worth a shot...)"
        if !resetSprites
            @warn "F5 to resume is even more dangerous than Ctrl+F5, the crashed frame will not be repeated"
                 +"but its effects prior to the crash will still have taken place. It's your funeral buddy."
    if program.crashed
        # TODO: sound
        # globalUnpause(soundWorld)
    end
    program.crashed = false
    program.loading = false
    # betamax:
    # if(loadingPhaseTimerContext!=null) {
    #         loadingPhaseTimerContext.close();
    #         loadingPhaseTimerContext = null;
    #     }
    if resetSprites
        @info "Resetting sprites"
        setAdvisor!( program.textureRegistry, nothing )
        if nothing != program.spriteRegistry
            close( program.spriteRegistry )
        end
        @info "Creating sprite registry"
        program.spriteRegistry = SpriteRegistry( program.spriteTemplateRegistry, program.frameClock )
        @info "Setting texture load advisor"
        textureLoadAdvisor = TextureLoadAdvisorImpl( program.spriteRegistry, program.textureRegistry )
        program.textureRegistry.textureLoadAdvisor = textureLoadAdvisor
    end
    @debug "Creating script world"
    eventProcessor = EventProcessor( program.spriteRegistry, program.frameClock )
    globalScriptWorld = ScriptWorld( eventProcessor, globalScriptServicer )
    program.scriptWorld =
    scriptNames = mainScript.split(",")
    try
        @info "Loading scripts $scriptNames"
        loadScripts(scriptNames)
    catch e
        handleCrash(e)
    end

    resetLogicFrames( program.frameClock )
    # TODO: sound
    # betamax:
    # soundSyncer.reset();
    # soundSyncer.needResync();
    # resetPitch()

end


function updateView(p::DoomfishGlProgram)
    sprites = getSpritesInRenderOrder( p.spriteRegistry )
    # resyncIfNeeded( p.soundSyncer, sprites ) TODO: sound

    readyStats = @timed checkAllSpritesReadyToRender( p.textureRegistry, 10 * textureLoadGracePeriodFramePercent / p.frameClock.targetFps )
    ready = updateStats!( metrics, CHECK_ALL_SPRITES_READY_TO_RENDER, readyStats )

    # we do this after waiting for sprites to (likely) be in RAM but before rendering because rendering
    # will evict MemoryStrategy.STREAMING sprite frames, and we need that frame to do mouse click collisions
    pollEventsStats = @timed pollEvents(p)
    updateStats!( metrics, POLL_EVENTS, pollEventsStats )
    if ready
        exitLoadingMode(p)
        clearScreen(p)
        ramUnloadStats = @timed processRamUnloadQueue( p.textureRegistry )
        updateStats!( metrics, PROCESS_RAM_UNLOAD_QUEUE, ramUnloadStats )
        if !p.frameClock.paused
            renderSpritesStats = @timed renderAllSprites(p)
            updateStats!( metrics, RENDER_ALL_SPRITES, renderSpritesStats )
        end
    else
        enterLoadingMode(p)
    end
    showPauseScreen( p.frameClock.paused )
    # betamax:
    # updateDevConsole();
    # processKeyEvents();
    # FIXME: ^ I honestly think I just jammed this key events call in here
    # b/c I couldn't figure out where else it should go.

    # betamax: FIXME last minute messy code
    if (p.scriptWorld |> shouldReboot)
        newWorld(p)
    end
end





function updateFps(p::DoomfishGlProgram, newFps::Int)
    if newFps <= 0 return end
    p.frameClock.targetFps = newFps
end


function updateLogic(p::DoomfishGlProgram)
    try
        if !p.frameClock.paused dispatchEvents!( p.eventProcessor, p.scriptWorld ) end
    catch e
        handleCrash(e)
    end
end


function getActionStateString(p::DoomfishGlProgram)
    return crashed ? "CRASH" :
                    (loading ? "LOADING" :
                            (p.frameClock.paused ? "PAUSE" : "PLAY"))
end


function handleCrash(p:DoomfishGlProgram, e::Exception)
    @error "Crashed! This is usually due to a script bug, in which case you can try resuming."
    p.frameClock.paused = true
    # globalPause(p.soundWorld) TODO: sound
    p.crashed = true
end


function close(p::DoomfishGlProgram)
    close(p.spriteRegistry)
    close(p.spriteTemplateRegistry)
end
