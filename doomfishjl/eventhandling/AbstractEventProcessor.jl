
include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")
include("logic/AbstractLogicHandler.jl")
include("EventRegistry.jl")


@interface AbstractEventProcessor begin
    inputQueue::Vector{ Input }
    eventQueue::Vector{ Event }
end

@abstractMethod AbstractEventProcessor enqueueInput!( input::Input )
@abstractMethod AbstractEventProcessor processInputs!()

@abstractMethod AbstractEventProcessor enqueueEvent!( event::Event )
@abstractMethod AbstractEventProcessor dispatchEvents!( logicHandler::AbstractLogicHandler )
