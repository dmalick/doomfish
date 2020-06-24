include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("GlProgramBase.jl")


struct DumbshitGlProgram <: GlProgramBase

    mainWindow::GlWindow
    frameClock::GameLoopFrameClock
    eventProcessor::EventProcessor
    logicHandler::LogicHandler

end




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
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA )
end


function expensiveInitialize( program::DoomfishGlProgram )
    preloadTemplates( program.spriteTemplateRegistry )

end







function KeyInputEvent( p::DumbshitGlProgram, action::GLFW.Action, key::GLFW.Key, mods::Int )
    keyInput!( p.eventProcessor, action::GLFW.Action, key::GLFW.Key, mods::Int )
end

function MouseInputEvent( p::DumbshitGlProgram, window::GLFW.Window, action::GLFW.Action, button::GLFW.Button, mods::Int )
    mouseInput!( p.eventProcessor, window, action, button, mods )
end

function processInputs( p::DumbshitGlProgram )
    processInputs!( p.eventProcessor )
end

getDebugMode( p::DumbshitGlProgram ) = return debugMode

function close( p::DumbshitGlProgram )
    close( p.spriteRegistry )
    close( p.spriteTemplateRegistry )
end
