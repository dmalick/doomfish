include("/home/gil/doomfish/doomfishjl/engine/GlProgramBase.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/logic/DefaultLogic.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/AbstractEventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")


macro onEvent( event, callback )

    # passing a non-Event into the below call will crash, by design.
    # it's easier than manually checking the argument.
    # could do a try-catch but the error message for
    # checkEventRegistered is good enough.
    return quote
        checkState( glProgram isa GlProgramBase, "cannot register event: glProgram not set or initialized" )
        checkEventRegistered( glProgram.EventProcessor, glProgram.AbstractLogicHandler, $event )

        registerEvent!( glProgram.EventProcessor, $event )
        registerCallback!( glProgram.AbstractLogicHandler, $event, ()-> $callback )
    end
end


function checkEventRegistered( eventProcessor::AbstractEventProcessor, logicHandler::DefaultLogic, event::Event )
    checkArgument( eventProcessor.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !hasevent( eventProcessor, event ), "event $event already registered in EventProcessor.registeredEvents" )
    checkState( logicHandler.acceptingCallbacks, "AbstractLogicHandler $logicHandler not accepting callbacks: cannot register callbacks after world has already begun." )
    # below checkArgument's error string has the conditional in there b/c we'll get a key error if logicHandler.callbacks[event] doesn't exist.
    checkArgument( !hascallback( logicHandler, event ), "Callback already registered for event $event \n($( hascallback(logicHandler, event) ? logicHandler.callbacks[event] : "" ))" )
end






# @onEvent GlobalEvent(MOUSE_RELEASE) begin
#     println("mouse released")
# end
#
# enqueueEvent!(eventProcessor, GlobalEvent(MOUSE_RELEASE))
#
# dispatchEvents!(eventProcessor, logicHandler)
