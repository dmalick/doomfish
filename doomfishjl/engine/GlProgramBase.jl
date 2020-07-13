using GLFW
include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")
include("/home/gil/doomfish/doomfishjl/engine/FrameClock.jl")
# include("/home/gil/doomfish/doomfishjl/graphics/Texture.jl")
include("/home/gil/doomfish/doomfishjl/opengl/GlWindow.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")

@interface GlProgramBase begin

    mainWindow::Union{ GlWindow, Nothing }
    frameClock::FrameClock

end

@abstractMethod GlProgramBase initialize()
@abstractMethod GlProgramBase keyInputEvent( key::GLFW.Key, action::GLFW.Action, mods::Int )
@abstractMethod GlProgramBase mouseInputEvent( window::GLFW.Window, action::GLFW.Action, button::GLFW.MouseButton, mods::Int )
@abstractMethod GlProgramBase processInputs()
@abstractMethod GlProgramBase showInitialScreen()
# updateView could be called every frame, more than once per frame, less often, etc.
@abstractMethod GlProgramBase updateView()
# updateLogic will be called exactly once per logical frame, ie, once for frame 0, then once for frame 1, etc
@abstractMethod GlProgramBase updateLogic()
# @abstractMethod( GlProgramBase, getWindowTitle )
# @abstractMethod( GlProgramBase, getWindowHeight )
# @abstractMethod( GlProgramBase, getWindowWidth )
@abstractMethod GlProgramBase getDebugMode() # TODO: get from command line property
@abstractMethod GlProgramBase expensiveInitialize()
@abstractMethod GlProgramBase close()
@abstractMethod GlProgramBase onExit()


function runGlProgram( p::GlProgramBase )
    initGlfw( debug=getDebugMode(p) )
    # FIXME(?) kinda don't like having to define the key/mouse callbacks at runtime,
    # but all they do is call single other functions, which were defined at parse time,
    # so my guess is it's ok.
    # we'll see.
    mouseButtonCallback( window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Int32 ) =  mouseInputEvent( p, window, action, button, mods)
    keyCallback( window::GLFW.Window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32 ) = keyInputEvent( p, action, key, mods )
    try
        mainWindow = GlWindow( getWindowWidth(p), getWindowHeight(p), getWindowTitle(p),
                      keyCallback, mouseButtonCallback, startFullscreen )
        p.mainWindow = mainWindow
        # try
        @collectstats USER_INIT begin
            @checkGlError initialize(p)

            # @renderPhase includes the call to @collectstats RENDER
            @collectstats RENDER begin
                renderPhaseBegin( p.mainWindow )

                showInitialScreen(p)

                renderPhaseEnd( p.mainWindow )
            end

            @checkGlError expensiveInitialize(p)
            @debug "User initialization done"
        end
        resetLogicFrames!( p.frameClock )
        try
            while !shouldClose( p.mainWindow )
                loopOnce(p)
            end
        finally
            closeWindow( p.mainWindow )
        end
        # catch err
        #     @error "exiting due to exception $err"
        #     throw( err )
        # finally
        #     close(p)
        #end
    finally
        onExit(p)
        shutdownGlfw()
        #exit()
    end
end



# TODO: get from command line property
getDebugMode( p::GlProgramBase ) = return debugMode

reportMetrics() = return metrics.timeStats

pollEvents( p::GlProgramBase ) = pollEvents( p.mainWindow )



function loopOnce( p::GlProgramBase )

    @collectstats IDLE_TIME begin
        #@collectstats IDLE_TIME_5SEC begin
        if !sleepUntilNextLogicFrame( p.frameClock ) metrics.counters.skippedFramesByRenderCounter += 1 end
        #end
    end
    @collectstats VIDEO_FRAME_DRIFT begin
        # betamax:
        # careful moving videoFrameDriftTimer. It should start exactly when frameClock increments in its
        # beginLogicFrame and  end exactly when glfwSwapBuffers is called at the end of RenderPhase#close.
        # That said we are double buffered I guess so I'm not accounting for the time between the glfwSwapBuffers
        # call and the actual screen update. We don't exactly enclose those points here but it's fine because
        # and only as long as the other operations in between are of negligible time. I did check those BTW
        # to verify that and you should too if you change this code region, or else suck it up and manually
        # mark the videoFrameDriftTimer
        @collectstats FULL_LOGIC begin
            skippingFrames = false

            # WARNING: half assed, probably bad version of a java do-while loop.
            while ( skippingFrames = logicLoopOnce( p, skippingFrames ) ) continue end
        end
        @collectstats RENDER begin
            renderPhaseBegin( p.mainWindow )

            updateView(p)

            renderPhaseEnd( p.mainWindow )
        end
    end
end


function logicLoopOnce( p::GlProgramBase, skippingFrames::Bool )
    if skippingFrames
        metrics.counters.skippedFramesByLogicCounter += 1
    end
    @collectstats LOGIC begin
        # XXX this is NOT the proper use of the word "idempotent" Dom
        # betamax:
        # the pause function continues logic updates because logic updates should be idempotent in the absence
        # of user input, which can be useful. The frame clock should be checked and if duplicate frames are
        # received, no new time-triggered events should happen. This is the responsibility of the updateLogic
        # implementation.
        beginLogicFrame!( p.frameClock )
        updateLogic(p)
    end
    return moreLogicFramesNeeded( p.frameClock )
end
