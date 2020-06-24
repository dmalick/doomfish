include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/logic/LogicHandler.jl")


@interface ScriptBase begin

    spriteRegistry::SpriteRegistry
    eventProcessor::EventProcessor
    logicHandler::LogicHandler

    stateVariables::Dict{ String, Any }
    initializing::Bool
    
end

@abstractMethod ScriptBase loadScript( scriptName::String )
@abstractMethod ScriptBase getStateVariable( name::String )
@abstractMethod ScriptBase setStateVariable!( name::String, value )
