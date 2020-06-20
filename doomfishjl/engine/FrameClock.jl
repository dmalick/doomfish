
include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")


@interface FrameClock begin
    currentFrame::Int
    paused::Bool
    targetFps::Int
end

# implement the following

@abstractMethod(FrameClock, resetLogicFrames)
