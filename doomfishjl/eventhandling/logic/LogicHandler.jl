
include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")



@interface LogicHandler begin
    # no required fields
end



@abstractMethod LogicHandler onEvent( event::Event )
@abstractMethod LogicHandler onBegin()
@abstractMethod LogicHandler onLogicFrameEnd()
