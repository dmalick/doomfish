include("/home/gil/doomfish/doomfishjl/metrics/Metrics.jl")
include("eventtypes/Event.jl")
include("LogicHandler.jl")


struct DefaultLogic <: LogicHandler

    callbacks::Dict{ Event, Function }
    acceptingCallbacks::Bool

end
hascallback( λ::DefaultLogic, event::Event ) = haskey( λ.callbacks, event )


function registerCallback!( λ::DefaultLogic, event::Event, callback::Function )
    # betamax:
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkState( λ.acceptingCallbacks, "LogicHandler $λ not accepting callbacks: cannot register callbacks after world has already begun." )
    checkArgument( !hascallback( λ, event ), "Callback already registered for event $event \n($( λ.callbacks[event] ))" )
    λ.callbacks[event] = callback
end


function getCallback( λ::DefaultLogic, event::Event )
    checkArgument( hascallback( λ, event ), "No callback registered for event $event" )
    return λ.callbacks[event]
end


function onEvent( λ::DefaultLogic, event::Event )
    callback = getCallback( λ, event )
    @debug "handling event $event via $callback"
    @collectstats INVOKE_EVENT_CALLBACK callback()
end


function onBegin( λ::DefaultLogic )
    @info "onBegin"
    @collectstats INVOKE_BEGIN_CALLBACK onEvent( λ, GlobalEvent( BEGIN ) )
end
