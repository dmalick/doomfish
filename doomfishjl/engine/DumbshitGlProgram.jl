include("/home/gil/doomfish/doomfishjl/eventhandling/logic/DefaultLogic.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/input/inputhandling.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
#include("/home/gil/doomfish/doomfishjl/sprite/SpriteRegistry.jl")
include("/home/gil/doomfish/doomfishjl/scripting/scriptservicer.jl") # includes GlProgramBase, doomfishtool, globalvars
include("GameLoopFrameClock.jl")


mutable struct DumbshitGlProgram <: GlProgramBase

    mainWindow::Union{ GlWindow, Nothing }
    frameClock::GameLoopFrameClock

    eventRegistry::Union{ EventRegistry, Nothing }
    eventProcessor::Union{ EventProcessor, Nothing }
    logicHandler::DefaultLogic
    #spriteRegistry::SpriteRegistry

end

DumbshitGlProgram() = DumbshitGlProgram( nothing, GameLoopFrameClock(), EventRegistry(), nothing, DefaultLogic(), #=SpriteRegistry()=# )


function initialize()

    include("/home/gil/doomfish/doomfishjl/engine/allshaders.jl")
    prepareForDrawing()
    #prepareBuiltinTextures()

    # enable transparency
    glEnable( GL_BLEND )
    glEnable( GL_DEPTH_TEST )
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA )
end


expensiveInitialize( p::DumbshitGlProgram ) = @debug "expensiveInitialize" #preloadTemplates( p.spriteRegistry.spriteTemplateRegistry )


function updateView( p::DumbshitGlProgram )
    #sprites = getSpritesInRenderOrder( p.spriteRegistry )
    @debug "updateView"
end


function updateLogic( p::DumbshitGlProgram )
    @debug "updateLogic"
    pollEvents(p)
    processInputs(p)
    dispatchEvents(p)
end


function keyInputEvent( p::DumbshitGlProgram, action::GLFW.Action, key::GLFW.Key )
    keyInput( p.eventProcessor, action, key )
end

function mouseInputEvent( p::DumbshitGlProgram, window::GLFW.Window, action::GLFW.Action, button::GLFW.MouseButton )
    mouseInput( p.eventProcessor, window, action, button )
end

function processInputs( p::DumbshitGlProgram )
    processInputs!( p.eventProcessor )
end

function dispatchEvents( p::DumbshitGlProgram )
    dispatchEvents!( p.eventProcessor, p.logicHandler )
end

getDebugMode( p::DumbshitGlProgram ) = return debugMode

function close( p::DumbshitGlProgram )
    close( p.spriteRegistry )
    close( p.spriteTemplateRegistry )
end
