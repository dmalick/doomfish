includepath("doomfishjl/globalvars.jl")

includepath("doomfishjl/opengl/GlWindow.jl")

includepath("doomfishjl/graphics/Texture.jl")
includepath("doomfishjl/graphics/TextureRegistry.jl")
includepath("doomfishjl/graphics/SpriteTemplateRegistry.jl")

includepath("doomfishjl/sprite/SpriteRegistry.jl")

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
    glEnable(GL_BLEND)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end


# betamax has showInitialLoadingScreen() defined here. I moved it to GlProgramBase.


function expensiveInitialize(program::DoomfishGlProgram)
    preloadEverything(program.spriteTemplateRegistry)
    newWorld(program, resetSprites = true)
end


function prepareBuiltinTextures(program::DoomfishGlProgram)
    program.pausedTexture = simpleTexture(pausedTextureFile)
    program.crashTexture = simpleTexture(crashTextureFile)
    program.loadingTexture = simpleTexture(loadingTextureFile)
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
    scriptWorld = ScriptWorld(program.spriteRegistry)
    scriptNames = mainScript.split(",")
    try
        @info "Loading scripts $scriptNames"
        loadScripts()
end
