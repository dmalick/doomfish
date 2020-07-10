using ModernGL, GLAbstraction, GLFW, Logging
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("coordinates.jl")
include("GlErrorCodes.jl")


mutable struct GlWindow
    debugMode::Bool

    handle::GLFW.Window
    width::UInt32
    height::UInt32
    title::String

    isDestroyed::Bool
    fullscreen::Bool
end

# have to call this exactly once before any window can be created
function initGlfw( ;debug::Bool = debugMode )
    checkState( GLFW.Init(), "GLFW failed to initialize" )
    if debug
        JULIA_DEBUG = Main

        # original betamax code:
        # // enable glfw debugging

        # Configuration.DEBUG.set(true);
        # Configuration.DEBUG_LOADER.set(true);
        # Configuration.DEBUG_FUNCTIONS.set(true);
        # // we only currently use try-with-resources for stack memory
        # // Configuration.DEBUG_STACK.set(true);
        # // we don't yet use MemoryUtils
        # // Configuration.DEBUG_MEMORY_ALLOCATOR.set(true);
    end
end


# have to call this exactly once upon terminate. No windows can be subsequently created
shutdownGlfw() = GLFW.Terminate()


function GlWindow( width::Int, height::Int, title::String, keyCallback::Function, mouseButtonCallback::Function, fullscreen::Bool )
    glWindow = createWindow( width, height, title, fullscreen )

    GLFW.SetKeyCallback( glWindow.handle, keyCallback )
    GLFW.SetMouseButtonCallback( glWindow.handle, mouseButtonCallback )

    checkGlError()
    # original betamax code: LOG.debug("Created and showed window {} and completed setup of OpenGL context", windowHandle);
    @debug "Created and showed window $(glWindow.handle) and completed setup of OpenGL context."
    return glWindow
end


function createWindow( width::Int, height::Int, title::String, fullscreen::Bool ) :: GlWindow
    GLFW.DefaultWindowHints()
    GLFW.WindowHint( GLFW.RESIZABLE, false )
    # we'll hide the window til we're done making it.
    GLFW.WindowHint( GLFW.VISIBLE, false )
    GLFW.WindowHint( GLFW.CONTEXT_VERSION_MAJOR, 3 )
    GLFW.WindowHint( GLFW.CONTEXT_VERSION_MINOR, 2 )
    GLFW.WindowHint( GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE )
    if debugMode
        GLFW.WindowHint( GLFW.OPENGL_DEBUG_CONTEXT, true )
    end

    createdWindowHandle = fullscreen ?
        GLFW.CreateWindow( width, height, title, GLFW.GetPrimaryMonitor() ) :
        GLFW.CreateWindow( width, height, title )
    checkState( nothing != createdWindowHandle, "window not created" )

    glWindow = GlWindow( debugMode, createdWindowHandle, width, height, title, false, fullscreen )

    if !fullscreen
        centerWindow( glWindow )
    end

    if !showSystemCursor
        GLFW.SetInputMode( createdWindowHandle, GLFW.CURSOR, GLFW.CURSOR_HIDDEN )
    end

    GLFW.MakeContextCurrent( createdWindowHandle )
    GLFW.ShowWindow( createdWindowHandle )
    #TODO: in java there is the line GL.createCapabilities(). Does this matter to us?
    # the command doesn't seem to exist in any of the Julia modules
    GLFW.SwapInterval(1) # wait for vsync (or whatever) when swapping buffers

    if debugMode
        # enable opengl debugging
        glEnable( GL_DEBUG_OUTPUT )
        glDebugMessageCallback( @cfunction( debugMessageCallback, Nothing, (UInt32, UInt32, UInt32, UInt32, Int, String, Ptr{Nothing}) ) , Ptr{Nothing}(0) )
        # original betamax code:
        # GlDebugMessages.setupJavaStyleDebugMessageCallback(LOG);
        # // glDisable(GL_CULL_FACE);
    end

    return glWindow

end

function shouldClose( glWindow::GlWindow )
    #checkState()
    return GLFW.WindowShouldClose( glWindow.handle )
end

function centerWindow( glWindow::GlWindow )
    vidmode = getResolution()
    GLFW.SetWindowPos( glWindow.handle,
                      (vidmode.width ÷ glWindow.width) ÷ 2,
                      (vidmode.height ÷ glWindow.height) ÷ 2 )
end

function setShouldClose( glWindow::GlWindow, shouldClose::Bool )
    checkstate( !glWindow.isDestroyed )
    GLFW.SetWindowShouldClose( glWindow.handle, shouldClose )
end

function closeWindow( glWindow::GlWindow )
     checkState( !glWindow.isDestroyed )
     GLFW.DestroyWindow( glWindow.handle )
     # original betamax code: glfwFreeCallbacks(windowHandle);
     glWindow.isDestroyed = true
end

function windowToCoordinate( x::Float64, y::Float64; coordType::GlCoordinate = TextureCoordinate )
    if glWindow.fullscreen
        vidmode = getResolution()
        fieldWidth = vidmode.width
        fieldHeight = vidmode.height
    else
        fieldWidth = glWindow.width
        fieldHeight = glWindow.height
    end

    # we start with a TextureCoordinate (b/c the math is simpler), and convert from there.
    return convert( coordType, TextureCoordinate( x / fieldWidth, 1.0 - y / fieldHeight ) )
end


# WARNING mouse cursor coordinates are wrapped in separate DoubleBuffers in the original betamax code.
# be aware that this may come to bite us.
getCursorPosition( glWindow::GlWindow; coordType::GlCoordinate = TextureCoordinate ) = getCursorPosition( glWindow.handle, coordType )

function getCursorPosition( windowHandle::Int64; coordType::GlCoordinate = TextureCoordinate )
    cursorPosition = GLFW.GetCursorPos( windowHandle )
    x = cursorPosition.x
    y = cursorPosition.y
    return windowToCoordinate( x, y, coordType )

    # original betamax code:
    # private final DoubleBuffer xMousePosBuffer = BufferUtils.createDoubleBuffer(1);
    # private final DoubleBuffer yMousePosBuffer = BufferUtils.createDoubleBuffer(1);
    # public TextureCoordinate getCursorPosition() {
    #     glfwGetCursorPos(windowHandle, xMousePosBuffer, yMousePosBuffer);
    #     double x = xMousePosBuffer.get(0);
    #     double y = yMousePosBuffer.get(0);
    #     return windowToTextureCoord(x,y);
end


getResolution() = GLFW.GetVideoMode( GLFW.GetPrimaryMonitor() )


function pollEvents( glWindow::GlWindow )
    checkState( !glWindow.isDestroyed )
    GLFW.PollEvents()
    checkGlError()
end


macro renderPhase( glWindow, body )
    # checkArgument( glWindow isa Symbol || glWindow.head === :., "first argument to @renderPhase must be a GlWindow; got $glWindow" )
    # checkArgument( eval( glWindow ) isa GlWindow, "first argument to @renderPhase must be a GlWindow; got $glWindow")
    checkArgument( body.head === :block, "@renderPhase (GlWindow) must be followed by a begin block" )
        return quote
            @collectstats RENDER begin
                renderPhaseBegin( $glWindow )
                $body
                renderPhaseEnd( $glWindow )
            end
        end
    end


function renderPhaseBegin( glWindow::GlWindow )
    checkState( !glWindow.isDestroyed && glWindow != nothing )
    GLFW.MakeContextCurrent( glWindow.handle )
    checkGlError()
end


function renderPhaseEnd( glWindow::GlWindow )
    checkState( !glWindow.isDestroyed )
    checkGlError()
    GLFW.SwapBuffers( glWindow.handle )
end
