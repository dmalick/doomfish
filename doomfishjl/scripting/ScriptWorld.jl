include("/home/gil/doomfish/doomfishjl/eventhandling/eventtypes/GlobalEvent.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/eventtypes/SpriteEvent.jl")
include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")
include("/home/gil/doomfish/doomfishjl/scripting/scriptservicer.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("LogicHandler.jl")


struct ScriptWorld <: LogicHandler

    clock::FrameClock

    spriteRegistry::spriteRegistry
    eventProcessor::EventProcessor

    callbacks::Dict{Event, Function}
    stateVariables::Dict{String, Any}
    globalShaderName::Union{String, Nothing}

    initializing::Bool
    acceptingRegistrations::Bool
    rebootFlag::Bool
    ScriptWorld(σ::SpriteRegistry, ϵ::EventProcessor, f::frameClock) = new( f, σ, ϵ, Dict{String, Any}(),
                                                       defaultGlobalShaderName, true, false )
end


# I made the decision to keep registerCallback!() in ScriptWorld instead of putting it in the EventProcessor b/c
# the callbacks really have nothing to do w/ anything but scripts, and how the LogicHandler (in this case ScriptWorld)
# deals w/ them in the first place seems too implementation-specific to hardcode into something concrete
# like the EventProcessor.
function registerCallback!(σ::ScriptWorld, event::Event, callback::Function)
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkArgument( σ.acceptingRegistrations, "cannot register events after world has already begun" )
    checkArgument( !haskey( σ.callbacks, event ), "event $event already registered in ScriptWorld.callbacks" ) )
    σ.callbacks[event] = callback
end


function getCallback(σ::Scriptworld, event::Event)
    checkArgument( haskey(σ.callbacks, event), "event $event not registered in $(σ.callbacks)" )
    return σ.callbacks[event]
end


function invokeCallback(callback::Function, statsType::StatsName)
    invokeEventCallbackStats = @timed callback()
    updateStats!( metrics, statsType, invokeEventCallbackStats )
end


function onEvent(σ::ScriptWorld, event::Event)
    checkArgument( haskey( σ.eventProcessor, event ), "event $event not registered in $(σ.eventProcessor.registeredEvents)" )
    callback = getCallback( σ, event )
    @debug "handling event $event via $callback"
    invokeCallback( callback, INVOKE_EVENT_CALLBACK )
end


function onBegin(σ::ScriptWorld)
    @info "onBegin"
    checkArgument( haskey( σ.eventProcessor, GlobalEvent(BEGIN) ), "GlobalEvent(BEGIN) not registered in $(σ.eventProcessor.registeredEvents)" )
    callback = σ.eventProcessor.registeredEvents[ GlobalEvent(BEGIN) ]
    invokeCallback( callback, INVOKE_BEGIN_CALLBACK )
end


# we just reduced betamax's 19 lines of script loading code to 7.
# I ♥ Julia

function loadScripts(σ::ScriptWorld, scriptNames::Vector{String})
    for scriptName in scriptNames
        checkArgument( scriptName |> isfile, "invalid script path: $scriptName" )
        loadScript(σ, scriptName)
    end
    σ.initializing = false
end


# WARNING: not sure the "include" below will do quite what I want it to
function loadScript(σ::ScriptWorld, scriptName::String)
    σ.eventProcessor.acceptingRegistrations = true
    @info "Evaluating script from $scriptName"
    include(scriptName)
    σ.eventProcessor.acceptingRegistrations = false
end


function checkInit(σ::ScriptWorld)
    checkState( !σ.initializing, "Only callback registration may be performed during initialization" )
end


function finishInit!(σ::ScriptWorld)
    σ.initializing = false
end


getRegisteredEvents(σ::ScriptWorld) = return σ.eventProcessor.registeredEvents
getRegisteredEvents(σ::ScriptWorld, type::Type{T}) where T <: Event = filter( (event)-> typeof(event.first) == type, getRegisteredEvents(σ) )


getCallbacks(σ::ScriptWorld) = return values( σ.eventProcessor.registeredEvents )
getCallbacks(σ::ScriptWorld, eventType::Type{T}) where T <: Event = [ (event.second) for event in getRegisteredEvents(σ) if typeof(event.first) == eventType ]


getGlobalShader(σ::ScriptWorld) = getGlobalShaderName( σ.globalShader )

function setGlobalShader!(σ::ScriptWorld, shaderName::String)
    σ.globalShader = shaderName
end


function getStateVariable(σ::ScriptWorld, name::String)
    checkArgument( haskey( σ.stateVariables, name ), "no such state variable: $name" )
    return σ.stateVariables[name]
end

function setStateVariable(σ::ScriptWorld, name::String, value)
    σ.stateVariables[name] = value
end


#betamax: FIXME 13am code
shouldReboot(σ::ScriptWorld) = return σ.rebootFlag

function reboot!(σ::ScriptWorld)
    σ.rebootFlag = true
    @info "Rebooting everything (scheduled)"
end
