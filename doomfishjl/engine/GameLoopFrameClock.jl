
include("FrameClock.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")


struct GameLoopFrameClock <: FrameClock

    # betamax uses a java long type so we're casting this Int64 explicitly
    nextLogicFrameTime::Int64

    currentFrame::Int # = 0
    targetFps::Int # = targetFps (from globalvars)
    paused::Bool # = false

    # WARNING it looks like the java doesn't explicitly define a constructor for this(?)
    GameLoopFrameClock(nextLogicFrameTime::Int64) = new( nextLogicFrameTime, 0, targetFps, false )
end


function setPaused!(clock::GameLoopFrameClock, paused::Bool)
    if clock.paused == paused
        return
    elseif paused
        # we need to ignore the time spent in pause, otherwise we'll get a flood of catch up logic frames
        # and rendering will appear to skip
        @info "paused"
    else
        resetLogicFrames!(clock)
        @info "unpaused"
    end
    clock.paused = paused
end


function setTargetFps!(clock::GameLoopFrameClock, targetFps::Int)
    checkArgument( targetFps > 0 )
    clock.targetFps = targetFps
    @info "New target fps: $targetFps"
end


function beginLogicFrame!(clock::GameLoopFrameClock)
    if !clock.paused
        clock.currentFrame += 1
    end
    # the hardcoded 1000 below is b/c we're using our own time_ms function
    # to measure time in milliseconds rather than Julia's time or time_ns
    # functions which measure in seconds and nanoseconds respectfully
    clock.nextLogicFrameTime += 1000 / targetFps
end


function stepFrame!(clock::GameLoopFrameClock)
    if clock.paused
        clock.currentFrame += 1
    end
end


# WARNING: if the -1 below is a java 0-indexing thing we'll run into problems
sleepTillNextLogicFrame(clock::GameLoopFrameClock) = sleepUntilPrecisely(clock.nextLogicFrameTime - 1)


moreLogicFramesNeeded(clock::GameLoopFrameClock) = return !clock.paused && (time_ms() > clock.nextLogicFrameTime)


function resetLogicFrames!(clock::GameLoopFrameClock)
    @debug "Reset logic frame counter"
    clock.nextLogicFrameTime = time_ms()
end


function setCurrentFrame!(clock::GameLoopFrameClock, frame::Int)
    clock.currentFrame = frame
end
