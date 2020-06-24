
include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/logic/DefaultLogic.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")


macro onEvent( event, callback )
    checkArgument( argIs( event, :call ), "first arg to @onEvent must be an Event"  )
    checkArgument( argIs( callback, :block ), "second arg to @onEvent must be a begin block" )

    # passing a non-Event into the below call will crash, by design.
    # it's easier than manually checking the argument.
    return quote
        checkEventRegistered( program.EventProcessor, program.LogicHandler, $event )
        registerEvent!( program.EventProcessor, $event )
        registerCallback!( program.LogicHandler, $event, ()-> $callback )
    end
end


function checkEventRegistered( eventProcessor::EventProcessor, logicHandler::DefaultLogic, event::Event )
    checkArgument( eventProcessor.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !hasevent( eventProcessor, event ), "event $event already registered in EventProcessor.registeredEvents" )
    checkState( logicHandler.acceptingCallbacks, "LogicHandler $logicHandler not accepting callbacks: cannot register callbacks after world has already begun." )
    # below checkArgument's error string has the conditional in there b/c we'll get a key error if logicHandler.callbacks[event] doesn't exist.
    checkArgument( !hascallback( logicHandler, event ), "Callback already registered for event $event \n($( hascallback(logicHandler, event) ? logicHandler.callbacks[event] : "" ))" )
end






@onEvent GlobalEvent(MOUSE_RELEASE) begin
    println("mouse released")
end

enqueueEvent!(eventProcessor, GlobalEvent(MOUSE_RELEASE))

dispatchEvents!(eventProcessor, logicHandler)