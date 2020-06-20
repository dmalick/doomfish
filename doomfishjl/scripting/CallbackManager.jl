import Base.getindex

struct Callbacks
    callbacks::Dict{Event, Function}
    acceptingRegistrations::Bool
    Callbacks() = new( Dict{Event, Function}(), true )
end

getindex(c::Callbacks, idx::Event) = return c.callbacks[idx]
setindex!(c::Callbacks, callback::Function, idx::Event)

haskey(c::Callbacks, key::Event) = haskey( c.callbacks, key )

# Decided to keep callback management separate from the EventProcessor, b/c
# the callbacks really have nothing to do w/ anything but scripts, and how the LogicHandler (in this case ScriptWorld)
# deals w/ them in the first place seems too implementation-specific to hardcode into something concrete
# like the EventProcessor.
function registerCallback!(σ::Callbacks, event::Event, callback::Function)
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkArgument( σ.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !haskey( σ, event ), "event $event already registered in CallbackManager" )
    σ[event] = callback
end


function getCallback(σ::CallbackManager, event::Event)
    checkArgument( haskey(σ, event), "event $event not registered in $(σ.callbacks)" )
    return σ[event]
end
