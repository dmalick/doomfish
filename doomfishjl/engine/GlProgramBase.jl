include("/home/gil/doomfish/pseudointerface/interface.jl")
include("/home/gil/doomfish/doomfishjl/opengl/GlWindow.jl")
include("/home/gil/doomfish/doomfishjl/engine/GameLoopFrameClock.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/inputhandling.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")

@interface GlProgramBase begin
    mainWindow::GlWindow
    frameClock::GameLoopFrameClock
    eventProcessor::EventProcessor
end

@abstractMethod( GlProgramBase, initialize )
@abstractMethod( GlProgramBase, keyInputEvent ) # key::Int, action::Int, mods::Int
@abstractMethod( GlProgramBase, mouseInputEvent ) # coord::TextureCoordinate, button::Int
# updateView could be called every frame, more than once per frame, less often, etc.
# betamax: it must be idempotent (not sure you're using that word right Dom)
@abstractMethod( GlProgramBase, updateView )
# updateLogic will be called exactly once per logical frame, ie, once for frame 0, then once for frame 1, etc
@abstractMethod( GlProgramBase, updateLogic )
# @abstractMethod( GlProgramBase, getWindowTitle )
# @abstractMethod( GlProgramBase, getWindowHeight )
# @abstractMethod( GlProgramBase, getWindowWidth )
# @abstractMethod( GlProgramBase, getDebugMode ) # TODO: get from command line property
@abstractMethod( GlProgramBase, expensiveInitialize )
@abstractMethod( GlProgramBase, close )


function runGlProgram(p::GlProgramBase)
    initGlfw( getDebugMode(p) )
    # FIXME(?) kinda don't like having to define these at runtime, but all they do is call a single other function,
    # which was defined at parse time, so my guess is it's ok.
    # we'll see.
    mouseButtonCallback(window::Int64, button::Int, action::Int, mods::Int) = mouseInput( p.eventProcessor, window, action, button, mods )
    keyCallback(window::Int64, key::Int, scancode::Int, action::Int, mods::Int) = keyInput( p.eventProcessor, action, key, mods )
    try
        mainWindow = GlWindow( getWindowWidth(p), getWindowHeight(p), getWindowTitle(p),
                      keyCallback, mouseButtonCallback, startFullscreen )
        p.mainWindow = mainWindow
        try
            userInitStats = @timed begin
                initialize(p)
                checkGlError()

                # should accomplish the same thing as the betamax
                renderPhaseBegin( p.mainWindow )
                showInitialLoadingScreen( p )
                renderPhaseEnd( p.mainWindow )

                # WARNING: betamax code is kinda funky here:
                # try (GlWindow.RenderPhase __unused_context = mainWindow.renderPhase()) {
                #             showInitialLoadingScreen();
                #         }

                checkGlError()
                expensiveInitialize(p)
                checkGlError()
                @debug "User initialization done"
            end
            updateStats!( metrics, USER_INIT, userInitStats )
            resetLogicFrames( p.frameClock )
            try
                while !shouldClose( p.mainWindow )
                    loopOnce(p)
                end
            finally
                closeWindow( p.mainWindow )
            end
        catch err
            @error "exiting due to exception $err"
        finally
            close(p)
        end
    finally
        shutdownGlfw()
        exit()
    end
end


function showInitialLoadingScreen(loadingTexture::Texture, shader::ShaderProgram)
    render( loadingTexture, TextureCoordinate(0.5,0.5), shader )
end


reportMetrics() = return Dict{StatsName, Dict{StatsFieldName,String}}( Stats.name => StatsAnalysis(Stats)
                                                                                 for Stats in values( metrics.statContainers ))

closeWindow(p::GlProgramBase) = setShouldClose( p.mainWindow, true )


pollEvents(p::GlProgramBase) = pollEvents( p.mainWindow )


function loopOnce(p::GlProgramBase)
    idleTimeStats = @timed begin
        idleTime5sStats = @timed begin
            if !sleepTilNextLogicFrame() metrics.counters.skippedFramesByRenderCounter += 1 end
        end
        updateStats!( metrics, IDLE_TIME_5SEC, idleTime5sStats )
    end
    updateStats!( metrics, IDLE_TIME, idleTimeStats )
    videoFrameDriftStats = @timed begin
        # betamax:
        # careful moving videoFrameDriftTimer. It should start exactly when frameClock increments in its
        # beginLogicFrame and exactly when glfwSwapBuffers is called at the end of RenderPhase#close.
        # That said we are double buffered I guess so I'm not accounting for the time between the glfwSwapBuffers
        # call and the actual screen update. We don't exactly enclose those points here but it's fine because
        # and only as long as the other operations in between are of negligible time. I did check those BTW
        # to verify that and you should too if you change this code region, or else suck it up and manually
        # mark the videoFrameDriftTimer
        fullLogicStats = @timed begin
            skippingFrames = false
            # half assed, probably bad version of a java do-while loop
            while true
                if (skippingFrames)  metrics.counters.skippedFramesByLogicCounter += 1  end
                logicStats = @timed begin
                    # the pause function continues logic updates because logic updates should be idempotent in the absence
                    # of user input, which can be useful. The frame clock should be checked and if duplicate frames are
                    # received, no new time-triggered events should happen. This is the responsibility of the updateLogic
                    # implementation.
                    beginLogicFrame!( p.frameClock )
                    updateLogic(p)
                end
                updateStats!( metrics, LOGIC, logicStats )
                # betamax:
                # the pause function continues logic updates because logic updates should be idempotent in the absence
                # of user input, which can be useful. The frame clock should be checked and if duplicate frames are
                # received, no new time-triggered events should happen. This is the responsibility of the updateLogic
                # implementation.
                skippingFrames = true
                if moreLogicFramesNeeded( p.frameClock ) continue
                else break end
            end
        end
        updateStats!( metrics, FULL_LOGIC, fullLogicStats )
        renderStats = @timed begin
            renderPhaseBegin( p.mainWindow )
            updateView( p )
            renderPhaseEnd( p.mainWindow )
        end
        updateStats!( metrics, RENDER, renderStats )
    end
    updateStats!( metrics, VIDEO_FRAME_DRIFT, videoFrameDriftStats )
end
