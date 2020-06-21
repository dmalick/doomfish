
include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")


@interface FrameClock begin
    currentFrame::Int
    targetFps::Int
    paused::Bool
end


@abstractMethod FrameClock beginLogicFrame!()
@abstractMethod FrameClock resetLogicFrames!()
@abstractMethod FrameClock moreLogicFramesNeeded()


function setTargetFps!( frameClock::FrameClock, targetFps::Int )
    checkArgument( targetFps > 0, "targetFps must be > 0." )
    frameClock.targetFps = targetFps
    @info "New target fps: $targetFps"
end
