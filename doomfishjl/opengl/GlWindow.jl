using ModernGL, GLAbstraction, GLFW, Logging
include("includepath.jl")
include("coordinates.jl")
includepath("doomfishjl/doomfishtool.jl")


mutable struct GlWindow
    debugMode::Bool

    handle::Union{GLFW.Window, Nothing}
    width::UInt32
    height::UInt32
    title::String

    isDestroyed::Bool
    fullscreen::Bool
end

# have to call this exactly once before any window can be created
function initGlfw(debugMode::Bool)
    if debugMode
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
    checkState(GLFW.Init(), "could not initialize GLFW")
end

# have to call this exactly once upon terminate. No windows can be subsequently created
function shutdownGlfw()
    GLFW.Terminate()
end

function GlWindow(windowWidth::Int, windowHeight::Int, title::String,
                     keyCallback::Function, mouseButtonCallback::Function, fullscreen::Bool)
    glWindow = GlWindow(false, nothing, windowWidth, windowHeight, title, false, fullscreen)
    glWindow.handle = createWindow(glWindow)

    GLFW.SetKeyCallback(glWindow.handle, keyCallback)
    GLFW.SetMouseButtonCallback(glWindow.handle, mouseButtonCallback)

    checkGlError()
    # original betamax code: LOG.debug("Created and showed window {} and completed setup of OpenGL context", windowHandle);
    @debug "Created and showed window $(glWindow.handle) and completed setup of OpenGL context."
    return glWindow
end


function createWindow(glWindow::GlWindow)
    GLFW.DefaultWindowHints()
    GLFW.WindowHint(GLFW.RESIZABLE, false)
    # we'll hide the window til we're done making it.
    GLFW.WindowHint(GLFW.VISIBLE, false)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    if glWindow.debugMode
        GLFW.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT, true)
    end

    createdWindowHandle = glWindow.fullscreen ?
        GLFW.CreateWindow(glWindow.width, glWindow.height, glWindow.title, GLFW.GetPrimaryMonitor()) :
        GLFW.CreateWindow(glWindow.width, glWindow.height, glWindow.title)
    checkState(nothing!=createdWindowHandle, "window not created")
    if !glWindow.fullscreen
        centerWindow(glWindow, createdWindowHandle)
    end

    if !systemVars.showSystemCursor
        GLFW.SetInputMode(createdWindowHandle, GLFW.CURSOR, GLFW.CURSOR_HIDDEN)
    end

    GLFW.MakeContextCurrent(createdWindowHandle)
    GLFW.ShowWindow(createdWindowHandle)
    #TODO: in java there is the line GL.createCapabilities(). Does this matter to us?
    GLFW.SwapInterval(1) # wait for vsync (or whatever) when swapping buffers

    if glWindow.debugMode
        # enable opengl debugging
        # original betamax code:
        # GlDebugMessages.setupJavaStyleDebugMessageCallback(LOG);
        # // glDisable(GL_CULL_FACE);
    end

    return createdWindowHandle

end

function getShouldClose(glWindow::GlWindow)
    #checkState()
    return GLFW.WindowShouldClose(glWindow.handle)
end

function centerWindow(glWindow::GlWindow, createdWindowHandle::GLFW.Window)
    vidmode = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor()) # returns the resolution
    GLFW.SetWindowPos(createdWindowHandle,
                                (vidmode.width ÷ glWindow.width) ÷ 2,
                                (vidmode.height ÷ glWindow.height) ÷ 2)
end

function shouldClose(glWindow::GlWindow, shouldClose::Bool)
    checkstate(!glWindow.isDestroyed)
    GLFW.SetWindowShouldClose(glWindow.handle, shouldClose)
end

function closeWindow(glWindow::GlWindow)
     checkState(!glWindow.isDestroyed)
     GLFW.DestroyWindow(glWindow.handle)
     # original betamax code: glfwFreeCallbacks(windowHandle);
     glWindow.isDestroyed = true
end

function windowToTextureCoordinate(glWindow::GlWindow, x::Float64, y::Float64)
    if glWindow.fullscreen
        vidmode = GLFW.GetVideoMode(GLFW.GetPrimaryMonitor)
        fieldWidth = vidmode.width
        fieldHeight = vidmode.height
    else
        fieldWidth = glWindow.width
        fieldHeight = glWindow.height
    end

    return TextureCoordinate(x / fieldWidth, 1.0 - y / fieldHeight)
end


# the below betamax code is full of javaisms w/ no literal translation in julia. my guess is this will work.

# WARNING mouse cursor coordinates are wrapped in separate DoubleBuffers in the original betamax code.
# be aware that this may come to bite us.
function getCursorPosition(glWindow::GlWindow)
    cursorPosition = GLFW.GetCursorPos(glWindow.handle)
    x = cursorPosition.x
    y = cursorPosition.y
    return windowToTextureCoordinate(glWindow, x, y)
end

# wrote the below based closely on the betamax code, but wonder whether the RenderPhase struct is necessary
# struct RenderPhase end
#
# function renderPhaseClose(glWindow::GlWindow, renderPhase::RenderPhase)
#     checkState(!glWindow.isDestroyed)
#     checkGlError()
#     GLFW.SwapBuffers(glWindow.handle)
#     renderPhase = nothing
# end
#
# function renderPhase(glWindow::GlWindow)
#     checkState(!glWindow.isDestroyed)
#     GLFW.MakeContextCurrent(glWindow.handle)
#     checkGlError()
#     return RenderPhase()
# end

# original betamax code:
# private final DoubleBuffer xMousePosBuffer = BufferUtils.createDoubleBuffer(1);
# private final DoubleBuffer yMousePosBuffer = BufferUtils.createDoubleBuffer(1);
# public TextureCoordinate getCursorPosition() {
#     glfwGetCursorPos(windowHandle, xMousePosBuffer, yMousePosBuffer);
#     double x = xMousePosBuffer.get(0);
#     double y = yMousePosBuffer.get(0);
#     return windowToTextureCoord(x,y);
# }
#
# public final class RenderPhase implements AutoCloseable {
#     @Override public void close() {
#         checkState(!isDestroyed);
#         checkGlError();
#         glfwSwapBuffers(windowHandle);
#     }
#     private RenderPhase(){}
# }
#
# public GlWindow.RenderPhase renderPhase() {
#     checkState(!isDestroyed);
#     glfwMakeContextCurrent(windowHandle);
#     checkGlError();
#     return new RenderPhase();
# }


function renderPhaseBegin(glWindow::GlWindow)
    checkState(!glWindow.isDestroyed)
    GLFW.MakeContextCurrent(glWindow.handle)
    checkGlError()
end


function renderPhaseEnd(glWindow::GlWindow)
    checkState(!glWindow.isDestroyed)
    checkGlError()
    GLFW.SwapBuffers(glWindow.handle)
end


function pollEvents(glWindow::GlWindow)
    checkState(!glWindow.isDestroyed)
    GLFW.PollEvents()
    checkGlError()
end
