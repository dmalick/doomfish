
include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")


@interface LogicHandler begin
    # empty
end

# implement the following

@abstractMethod( LogicHandler, onEvent )
@abstractMethod( LogicHandler, onBegin )
