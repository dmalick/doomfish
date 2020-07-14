include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("AbstractLogicHandler.jl")


# storing/handling callbacks in the AbstractLogicHandler is the obvious choice,
# but we don't strictly require it.

mutable struct DefaultLogic <: AbstractLogicHandler

    callbacks::Dict{ Event, Function }
    acceptingCallbacks::Bool

    DefaultLogic() = new( Dict{ Event, Function }(), true )
end
hascallback( λ::DefaultLogic, event::Event ) = haskey( λ.callbacks, event )


function registerCallback!( λ::DefaultLogic, event::Event, callback::Function )
    # betamax:
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkState( λ.acceptingCallbacks, "AbstractLogicHandler $λ not accepting callbacks: cannot register callbacks after world has already begun." )
    # below checkArgument's error string has the conditional in there b/c we'll get a key error if λ.callbacks[event] doesn't exist.
    checkArgument( !hascallback( λ, event ), "Callback already registered for event $event \n($( hascallback(λ, event) ? λ.callbacks[event] : "" ))" )
    λ.callbacks[event] = callback
end


function callbackOverride!( λ::DefaultLogic, event::Event, callback::Function )
    @warn "overriding callback $(getCallback(λ, event)) for event $event"
    λ.callbacks[event] = event
end


function getCallback( λ::DefaultLogic, event::Event )
    checkState( hascallback( λ, event ), "No callback registered for event $event" )
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


function onLogicFrameEnd( λ::DefaultLogic )
    frameEndCallbacks = [ pair.second #=callback=# for pair in λ.callbacks if pair.first#=event=#.eventType === LOGIC_FRAME_END ]
    @collectstats ON_LOGIC_FRAME_END begin
        for callback in frameEndCallbacks @collectstats INVOKE_EVENT_CALLBACK callback() end
    end
end
