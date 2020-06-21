using OrderedCollections
include("EventTypes.jl")

abstract type Event end

EVENT_PRIORITIES = OrderedDict{ Int, Vector{EventType} }(
    1 => [ SPRITE_MOMENT, MOMENT ],
    2 => [ BEGIN ]
)

# EVENT_PRIORITIES = [
#     MOMENT, SPRITE_MOMENT,
#
# ]
