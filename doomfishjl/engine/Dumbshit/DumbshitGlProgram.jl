include("/home/gil/doomfish/doomfishjl/eventhandling/input/inputhandling.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/logic/DefaultLogic.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
#include("/home/gil/doomfish/doomfishjl/sprite/SpriteRegistry.jl")
include("/home/gil/doomfish/doomfishjl/opengl/VAO.jl")
include("/home/gil/doomfish/doomfishjl/opengl/VBO.jl")
include("/home/gil/doomfish/doomfishjl/engine/GlProgramBase.jl") # includes GlProgramBase, doomfishtool, globalvars
include("/home/gil/doomfish/doomfishjl/engine/allshaders.jl")
include("/home/gil/doomfish/doomfishjl/engine/GameLoopFrameClock.jl")
include("AbstractDumbshitGlProgram.jl")

includeDir("/home/gil/doomfish/doomfishjl/eventhandling/event/events/")


# DumbshitGlProgram is FOR TESTING PURPOSES ONLY


vertices = Array{Float32}([-0.5,  0.5, 1.0, 0.0, 0.0,
                            0.5,  0.5, 0.0, 1.0, 0.0,
                            0.5, -0.5, 0.0, 0.0, 1.0,
                           -0.5, -0.5, 1.0, 1.0, 1.0])

elements = Array{UInt32}([0,1,2,2,3,0])


defaultGlobalShaderName = "corners"


mutable struct DumbshitGlProgram <: AbstractDumbshitGlProgram # <: GlProgramBase

    mainWindow::Union{ GlWindow, Nothing }
    frameClock::GameLoopFrameClock

    eventRegistry::Union{ EventRegistry, Nothing }
    eventProcessor::Union{ EventProcessor, Nothing }
    logicHandler::DefaultLogic

    globalShader::Union{ ShaderProgram, Nothing }
    #spriteRegistry::SpriteRegistry

end

DumbshitGlProgram() = DumbshitGlProgram( nothing, GameLoopFrameClock(), EventRegistry(), nothing, DefaultLogic(), nothing, #=SpriteRegistry()=# )


getWindowWidth( p::DumbshitGlProgram ) = return 800
getWindowHeight( p::DumbshitGlProgram ) = return 600
getWindowTitle( p::DumbshitGlProgram ) = return "window"

function initShaderProgram( p::DumbshitGlProgram )
    vao = VAO()
    bindVAO(vao)
    vbo = VBO()
    bindAndLoadVBO( vbo, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices )
    ebo = VBO()
    bindAndLoadVBO( ebo, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, elements )

    p.globalShader = getShaderProgram( defaultGlobalShaderName )
    @info "globalShader = $(p.globalShader)"
    useProgram( p.globalShader )
end

function toggleDebug()
    global debugMode
    if debugMode
        @info "debug mode off"
        ENV["JULIA_DEBUG"] = nothing
    else
        @info "debug mode on"
        ENV["JULIA_DEBUG"] = Main
    end
    debugMode = !debugMode
end

function registerUniformEvent( p::DumbshitGlProgram, uniformName::String, event::Event, ftn::Function  )

    uniformLocation = getUniformLocation( uniformName, p.globalShader )
    registerEvent( p, event, ftn(uniformLocation) )

end

function registerTransforms( p::DumbshitGlProgram )


    upUni = getUniformLocation( "up", p.globalShader )
    registerEvent( p, GlobalEvent( KEY_PRESS, GLFW.KEY_UP ), ()-> glUniform1f( upUni, 0.25f0 ) )
    registerEvent( p, GlobalEvent( KEY_RELEASE, GLFW.KEY_UP ), ()-> glUniform1f( upUni, 0.0f0 ) )

    rightUni = getUniformLocation( "right", p.globalShader )
    registerEvent( p, GlobalEvent( KEY_PRESS, GLFW.KEY_RIGHT ), ()-> glUniform1f( rightUni, 0.25f0 ) )
    registerEvent( p, GlobalEvent( KEY_RELEASE, GLFW.KEY_RIGHT ), ()-> glUniform1f( rightUni, 0.0f0 ) )

    downUni = getUniformLocation( "down", p.globalShader )
    registerEvent( p, GlobalEvent( KEY_PRESS, GLFW.KEY_DOWN ), ()-> glUniform1f( downUni, -0.25f0 ) )
    registerEvent( p, GlobalEvent( KEY_RELEASE, GLFW.KEY_DOWN ), ()-> glUniform1f( downUni, 0.0f0 ) )

    leftUni = getUniformLocation( "left", p.globalShader )
    registerEvent( p, GlobalEvent( KEY_PRESS, GLFW.KEY_LEFT ), ()-> glUniform1f( leftUni, -0.25f0 ) )
    registerEvent( p, GlobalEvent( KEY_RELEASE, GLFW.KEY_LEFT ), ()-> glUniform1f( leftUni, 0.0f0 ) )


end


function initialize( p::DumbshitGlProgram )

    #prepareBuiltinTextures()
    # enable transparency
    glEnable( GL_BLEND )
    glEnable( GL_DEPTH_TEST )
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA )

    initShaderProgram(p)

    # registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_N), ()->( @info "`n` key pressed" ) )
    # registerEvent( p, GlobalEvent(KEY_RELEASE, GLFW.KEY_N), ()->( @info "`n` key released" ) )
    #
    # registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_S, mods = GLFW.MOD_CONTROL), ()-> display(metrics.timeStats) )
    # registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_D, mods = GLFW.MOD_CONTROL), ()-> toggleDebug() )
    #
    # registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_ESCAPE), ()-> setShouldClose(p.mainWindow, true) )
    # #registerEvent( p, GlobalEvent(KEY_REPEATED, key = GLFW.KEY_N), ()->( @info "`n` key repeated" ), input = KeyInput(GLFW.REPEAT, GLFW.KEY_N) )
    # registerCallback!( p.logicHandler, GlobalEvent(LOGIC_FRAME_END), ()-> return )

    #registerTransforms(p)

    p.eventProcessor = EventProcessor( p.eventRegistry )
    p.eventRegistry = nothing
    p.logicHandler.acceptingCallbacks = false
end



expensiveInitialize( p::DumbshitGlProgram ) = @debug "expensiveInitialize" #preloadTemplates( p.spriteRegistry.spriteTemplateRegistry )


function showInitialScreen( p::DumbshitGlProgram )

    # WARNING: these calls to getAttribLocation will fail (return -1) if they've
    # already been called once in the current Julia REPL session.
    # calling GLFW.Terminate() will not fix this!

    positionAttributeLocation = getAttribLocation( "position", p.globalShader )
    @info "typeof( positionAttributeLocation ) = $(typeof(positionAttributeLocation))"
    @info "value of positionAttributeLocation = $positionAttributeLocation"

    @checkGlError vertexAttribPointer( positionAttributeLocation, 2, Float32, false, 5, 0 )

    colorAttributeLocation = getAttribLocation("inColor", p.globalShader)
    @info "typeof( colorAttributeLocation ) = $(typeof(colorAttributeLocation))"
    @info "value of colorAttributeLocation = $colorAttributeLocation"

    @checkGlError vertexAttribPointer( colorAttributeLocation, 3, Float32, false, 5, 2 )

    upUni = getUniformLocation( "up", p.globalShader )
    glUniform1f( upUni, 0.0f0 )
    downUni = getUniformLocation( "down", p.globalShader )
    glUniform1f( downUni, 0.0f0 )
    leftUni = getUniformLocation( "left", p.globalShader )
    glUniform1f( leftUni, 0.0f0 )
    rightUni = getUniformLocation( "right", p.globalShader )
    glUniform1f( rightUni, 0.0f0 )

end


function updateView( p::DumbshitGlProgram )
    glClearColor( 0.0f0, 0.0f0, 0.0f0, 0.0f0 )
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
    drawElements( GL_TRIANGLES, 6, UInt32, 0 )
end


function updateLogic( p::DumbshitGlProgram )
    pollEvents(p)
    processInputs(p)
    dispatchEvents(p)
end


function keyInputEvent( p::DumbshitGlProgram, action::GLFW.Action, key::GLFW.Key, mods::Int32 )
    keyInput( p.eventProcessor, action, key, mods )
end

function mouseInputEvent( p::DumbshitGlProgram, window::GLFW.Window, action::GLFW.Action, button::GLFW.MouseButton, mods::Int32 )
    mouseInput( p.eventProcessor, window, action, button, mods )
end

function processInputs( p::DumbshitGlProgram )
    processInputs!( p.eventProcessor )
end

function dispatchEvents( p::DumbshitGlProgram )
    dispatchEvents!( p.eventProcessor, p.logicHandler )
end

getDebugMode( p::DumbshitGlProgram ) = return debugMode

function close( p::DumbshitGlProgram )
    # close( p.spriteRegistry )
    # close( p.spriteTemplateRegistry )
end

onExit( p::DumbshitGlProgram ) = outputStats ? display(metrics.timeStats) : return


function loadScripts( p::DumbshitGlProgram )

    p.logicHandler.acceptingCallbacks = true

    includeFiles( resourcePathBase * "scripts/" )

    p.logicHandler.acceptingCallbacks = false

end
