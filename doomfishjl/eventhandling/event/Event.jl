using OrderedCollections, GLFW
include("EventTypes.jl")
include("Moment.jl")

abstract type Event end


Key = Union{ GLFW.Key, Nothing }
MouseButton = Union{ GLFW.MouseButton, Nothing }


EVENT_PRIORITIES = OrderedDict{ Int, Vector{EventType} }(
    1 => [ SPRITE_MOMENT, MOMENT ],
    2 => [ BEGIN ]
)

# EVENT_PRIORITIES = [
#     MOMENT, SPRITE_MOMENT,
#
# ]
