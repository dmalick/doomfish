include("/home/gil/doomfish/doomfishjl/eventhandling/eventtypes/GlobalEvent.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/eventtypes/SpriteEvent.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/LogicHandler.jl")
include("/home/gil/doomfish/doomfishjl/scripting/ScriptServicer.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")


struct ScriptWorld <: LogicHandler
    eventProcessor::EventProcessor
    servicer::ScriptServicer
end


function invokeCallback(callback::Function, statsType::StatsName)
    invokeEventCallbackStats = @timed callback()
    updateStats!( metrics, statsType, invokeEventCallbackStats )
end


function onEvent(σ::ScriptWorld, event::Event)
    checkArgument( haskey( σ.servicer.callbacks, event ), "no callback function assigned to event $event" )
    callback = getCallback(σ.servicer, event)
    @debug "handling event $event via $callback"
    invokeCallback(callback, INVOKE_EVENT_CALLBACK)
end


function onBegin(σ::ScriptWorld)
    @info "onBegin"
    checkArgument( haskey( σ.servicer.callbacks, GlobalEvent(BEGIN) ), "no callback function assigned to event $event" )
    callback = getCallback( σ.servicer, GlobalEvent(BEGIN) )
    invokeCallback(callback, INVOKE_BEGIN_CALLBACK)
end


# we just reduced betamax's 19 lines of script loading code to 7.
# I ♥ Julia

function loadScripts(σ::ScriptWorld, scriptNames::Vector{String})
    scriptWorldVector = [σ for name in 1:scriptNames]
    map(loadScript, scriptWorldVector, scriptNames)
end


# WARNING: I'm not sure the "include" below will do quite what I want it to
function loadScript(σ::ScriptWorld, scriptName::String)
    σ.eventProcessor.acceptingCallbacks = true
    @info "Evaluating script from $scriptName"
    include(scriptName)
    finishInit(σ.servicer)
    σ.eventProcessor.acceptingCallbacks = false
end


getAllCallbacks(σ::ScriptWorld) = return σ.servicer.callbacks

getStateVariables(σ::ScriptWorld) = return σ.servicer.stateVariables

getGlobalShader(σ::ScriptWorld) = getGlobalShaderName(σ.servicer)

setGlobalShader(σ::ScriptWorld, shaderName::String) = setGlobalShader!( σ.servicer, shaderName )

function setStateVariables(σ::ScriptWorld, variables::Dict{String, String})
    for varname in keys(variables)
        σ.servicer.stateVariables[varname] = variables[varname]
    end
end

shouldReboot(σ::ScriptWorld) = return σ.servicer.rebootFlag
