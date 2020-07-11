include("/home/gil/doomfish/pseudointerface/interface/utils.jl")
include("/home/gil/doomfish/doomfishjl/engine/GlProgramBase.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/logic/DefaultLogic.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/AbstractEventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")


macro onEvent( event, callback )
    # passing a non-Event into the below call will crash, by design.
    # it's easier than manually checking the argument.
    return quote
        #@info "registering Event $event with callback $callback $($(event).input != nothing ? "on input $($(event).input)" : "" )"
        checkState( mainGlProgram.eventRegistry != nothing, "cannot register $event; EventRegistry already closed" )
        registerEvent!( mainGlProgram.eventRegistry, $event )
        registerCallback!( mainGlProgram.logicHandler, $event, $callback )
    end
end
