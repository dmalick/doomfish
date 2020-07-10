include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/logic/AbstractLogicHandler.jl")


@interface ScriptBase begin

    spriteRegistry::SpriteRegistry
    eventProcessor::EventProcessor
    logicHandler::AbstractLogicHandler

    stateVariables::Dict{ String, Any }
    initializing::Bool
    
end

@abstractMethod ScriptBase loadScript( scriptName::String )
@abstractMethod ScriptBase getStateVariable( name::String )
@abstractMethod ScriptBase setStateVariable!( name::String, value )
