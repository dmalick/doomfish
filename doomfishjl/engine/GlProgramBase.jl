
include("/home/gil/doomfish/pseudointerface/interface.jl")
include("/home/gil/doomfish/doomfishjl/opengl/GlWindow.jl")
include("/home/gil/doomfish/doomfishjl/engine/GameLoopFrameClock.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")


@interface GlProgramBase begin
    mainWindow::GlWindow
    frameClock::GameLoopFrameClock
end

@abstractMethod( GlProgramBase, initialize )
@abstractMethod( GlProgramBase, keyInputEvent ) # key::Int, action::Int, mods::Int
@abstractMethod( GlProgramBase, mouseClickEvent ) # coord::TextureCoordinate, button::Int
# updateView could be called every frame, more than once per frame, less often, etc.
# betamax: it must be idempotent (not sure you're using that word right Dom)
@abstractMethod( GlProgramBase, updateView )
# updateLogic will be called exactly once per logical frame, ie, once for frame 0, then once for frame 1, etc
@abstractMethod( GlProgramBase, updateLogic )
@abstractMethod( GlProgramBase, getWindowTitle )
@abstractMethod( GlProgramBase, getWindowHeight )
@abstractMethod( GlProgramBase, getWindowWidth )
@abstractMethod( GlProgramBase, getDebugMode ) # TODO: get from command line property
@abstractMethod( GlProgramBase, expensiveInitialize )
@abstractMethod( GlProgramBase, close )


function runGlProgram(program::GlProgramBase)
    initGlfw( getDebugMode(program) )
    try
        mainWindow = GlWindow( getWindowWidth(program), getWindowHeight(program), getWindowTitle(program),
                      keyCallback, mouseButtonCallback, startFullscreen )
        program.mainWindow = mainWindow
        try
            userInitStats = @timed begin
                initialize(program)
                checkGlError()

                # should accomplish the same thing as the betamax
                renderPhaseBegin( program.mainWindow )
                showInitialLoadingScreen( program )
                renderPhaseEnd( program.mainWindow )

                # WARNING: betamax code is kinda funky here:
                # try (GlWindow.RenderPhase __unused_context = mainWindow.renderPhase()) {
                #             showInitialLoadingScreen();
                #         }

                checkGlError()
                expensiveInitialize(program)
                checkGlError()
                @debug "User initialization done"
            end
            updateTimedStats!( metrics, USER_INIT, userInitStats )
            resetLogicFrames(program.frameClock)
            try
                while !getShouldClose(program.mainWindow)
                    loopOnce(program)
                end
            finally
                closeWindow(program.mainWindow)
            end
        catch err
            @error "exiting due to exception $err"
        finally
            close(program)
        end
    finally
        shutdownGlfw()
        exit()
    end
end


function showInitialLoadingScreen(loadingTexture::Texture, shader::ShaderProgram)
    render( loadingTexture, TextureCoordinate(0.5,0.5), shader )
end


# TODO: may need to adjust what this does w/ 'window'
function mouseButtonCallback(program::GlProgramBase, window::Int64, button::Int, action::Int, mods::Int)
    if action == GLFW.PRESS
        coord = getCursorPosition(window)
        if coord |> isValidCoordinate
            mouseClickEvent(program, coord, button)
        else
            @warn "Out of bounds $coord due to excessively delayed handling of mouse click"
        end
    end
end


getCursorPosition(program::GlProgramBase) = getCursorPosition(program.mainWindow)


keyCallback(window::Int64, key::Int, scancode::Int, action::Int, mods::Int) = keyInputEvent(key, action, mods)


reportMetrics() = return Dict{TimedStatsName, Dict{TimedStatsFieldName,String}}( timedStats.name => timedStatsAnalysis(timedStats)
                                                                                 for timedStats in values( metrics.timedStatContainers ))

closeWindow(program::GlProgramBase) = shouldClose( program.mainWindow, true )


pollEvents(program::GlProgramBase) = pollEvents( program.mainWindow )


function loopOnce(program::GlProgramBase)
    idleTimeStats = @timed begin
        idleTime5sStats = @timed begin
            if !sleepTilNextLogicFrame() metrics.counters.skippedFramesByRenderCounter += 1 end
        end
        updateTimedStats!( metrics, IDLE_TIME_5SEC, idleTime5sStats )
    end
    updateTimedStats!( metrics, IDLE_TIME, idleTimeStats )
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
                    beginLogicFrame!(program.frameClock)
                    updateLogic(program)
                end
                updateTimedStats!( metrics, LOGIC, logicStats )
                # betamax:
                # the pause function continues logic updates because logic updates should be idempotent in the absence
                # of user input, which can be useful. The frame clock should be checked and if duplicate frames are
                # received, no new time-triggered events should happen. This is the responsibility of the updateLogic
                # implementation.
                skippingFrames = true
                if moreLogicFramesNeeded( program.frameClock ) continue
                else break end
            end
        end
        updateTimedStats!( metrics, FULL_LOGIC, fullLogicStats )
        renderStats = @timed begin
            renderPhaseBegin( program.mainWindow )
            updateView( program )
            renderPhaseEnd( program.mainWindow )
        end
        updateTimedStats!( metrics, RENDER, renderStats )
    end
    updateTimedStats!( metrics, VIDEO_FRAME_DRIFT, videoFrameDriftStats )
end
