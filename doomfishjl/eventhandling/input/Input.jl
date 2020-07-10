
include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")


abstract type Input end

# the reason this is here and not in the EventProcessor is that we want to allow for
# special cases where inputs may need to be checked/altered before being registered
# (e.g., MouseInputs include specific coordinates, but of course we can't register
# a separate version of a MouseInput for EVERY possible coordinate, so we'd write
# a specific method of registerInput! for dealing w/ MouseInputs).

registerInput!( inputMap::Dict{ Input, Vector{Event} }, event::Event, input::Input ) = registerInput_finalize!( inputMap, event, input )

# helper method, only be called by methods of registerInput!.
function registerInput_finalize!( inputMap::Dict{ Input, Vector{Event} }, event::Event, input::Input )
    if !haskey( inputMap, input ) inputMap[input] = Vector{Event}() end
    checkState( !( event in inputMap[input] ), "event $event already registered for input $(event.input)" )
    push!( inputMap[input], event )
end


# the inverse of the above case is the inputToEvents function, for cases in which just
# looking up the Input in the inputMap Dict is not sufficient, i.e. the generated
# events actually REQUIRE data from the dequeued Input that the generic Input (registered
# in the inputMap) does not have.

# the generic method of inputToEvents just looks up the event list in the inputMap and
# returns it. More specific methods should be written for Input types that require them.

inputToEvents( inputMap::Dict{ Input, Vector{Event} }, input::Input ) = return inputMap[input]
