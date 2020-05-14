
include("/home/gil/doomfish/pseudointerface/interface.jl")


@interface LogicHandler begin
    # empty
end

# implement the following

@abstractMethod( LogicHandler, onBegin )
@abstractMethod( LogicHandler, onSpriteEvent )
