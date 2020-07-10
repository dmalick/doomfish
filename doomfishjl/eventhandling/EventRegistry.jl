
include("input/Input.jl") # includes Event.jl


# the EventRegistry is only modifiable prior to creation of the world, at which
# point it is passed to the constructor of the EventProcessor, which is created
# from it, after which it is set to `nothing` and falls out of scope.

mutable struct EventRegistry
    registeredInputs::Vector{ Input }
    registeredEvents::Vector{ Event }
    EventRegistry() = new( Vector{ Input }(), Vector{ Event }() )
end


function registerEvent!( ϵ::EventRegistry, event::Event )
    checkArgument( !( event in ϵ.registeredEvents ), "event $event already registered" )

    @info "registering event $event"
    push!( ϵ.registeredEvents, event )
    if hasfield( typeof(event), :input ) && !( event.input in ϵ.registeredInputs )
        push!( ϵ.registeredInputs, event.input )
    end
end
