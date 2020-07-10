
include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")


@interface AbstractLogicHandler begin
    # no required fields
end

@abstractMethod AbstractLogicHandler onEvent( event::Event )
@abstractMethod AbstractLogicHandler onBegin()
@abstractMethod AbstractLogicHandler onLogicFrameEnd()
