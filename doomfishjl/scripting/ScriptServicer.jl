include("/home/gil/doomfish/doomfishjl/eventhandling/EventProcessor.jl")


# FIXME(?): the whole "ScriptServicer" abstraction was meant as an intermediary between java and python.
# wonder whether it's really necessary in its current form
# TODO: in any case, as this file swells, break it up

struct ScriptServicer
    eventProcessor::EventProcessor
    callbacks::Dict{Event, Function}
    stateVariables::Dict{String, String}
    globalShaderName::Union{String, Nothing}
    initializing::Bool
    rebootFlag::Bool
    ScriptServicer(eventProcessor::EventProcessor) = new(eventProcessor, Dict{Event, Function}(), nothing,
                                                         Dict{String, String}(), true, false)
end


checkInit(servicer::ScriptServicer) = checkState( !servicer.initializing,
                                            "Only callback registration may be performed during initialization" )

function finishInit!(servicer::ScriptServicer)
    servicer.initializing = false
end





# callback handling

function registerCallback!(servicer::ScriptServicer, event::Event, callback::Function)
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkArgument( servicer.eventProcessor.acceptingCallbacks, "cannot alter callbacks after already begun" )
    checkArgument( !haskey(servicer.callbacks, event), "Callback already registered for $event:
        $(servicer.callbacks[event])" )
    servicer.callbacks[event] = callback
end


function registerSpriteCallback!(servicer::ScriptServicer, eventType::EventType, spriteName::SpriteName,
                                callback::Function; moment::Union{Int, Nothing}=nothing, key::Union{Int, Nothing}=nothing)
    spriteEvent = SpriteEvent( eventType, spriteName, moment=moment, key=key )
    registerCallback( servicer, spriteEvent, callback )
end


function registerGlobalCallback!(servicer::ScriptServicer, eventType::EventType, callback::Function)
    globalEvent = GlobalEvent( eventType )
    registerCallback( servicer, globalEvent, callback )
end


getCallback(servicer::ScriptServicer, spriteEvent::SpriteEvent) = return ScriptServicer.callbacks[spriteEvent]


function getCallbacksByType(servicer::ScriptServicer, type::Type{T}) where T <: Event
    return filter( event -> (event.first isa type), servicer.callbacks )
end


getSpriteCallbacks(servicer::ScriptServicer) = getCallbacksByType(servicer, SpriteEvent)
getGlobalCallbacks(servicer::ScriptServicer) = getCallbacksByType(servicer, GlobalEvent)


#=

TODO: EVENT-SPECIFIC CALLBACK REGISTERS GO HERE

=#





# sprite handling

function getSpriteByName(servicer::ScriptServicer, spriteName::SpriteName)
    checkInit(servicer)
    return getSpriteByName(eventProcessor, spriteName)
end


function spriteExists(servicer::ScriptServicer, spriteName::SpriteName)
    checkInit(servicer)
    return spriteExists( servicer.eventProcessor, spriteName )
end


function createSprite(servicer::ScriptServicer, templateName::String, spriteName::SpriteName)
    checkInit(servicer)
    createSprite( servicer.eventProcessor, templateName, spriteName )
end


function destroySprite(servicer::ScriptServicer, spriteName::SpriteName)
    checkInit(servicer)
    destroySprite( servicer.eventProcessor, spriteName)
end





# SpriteTemplate related functions

function loadSpriteTemplate(servicer::ScriptServicer, templateName::String)
    checkInit(servicer)
    loadSpriteTemplate( servicer.eventProcessor, templateName )
end


getFrameCount(servicer::ScriptServicer, templateName::String) = return getSpriteTemplate( servicer.eventProcessor, templateName ).frameCount


getNamedMoment(servicer::ScriptServicer, templateName::String, momentName::String) = getNamedMoment(servicer.eventProcessor, templateName, momentName)





# state variable / global shader handling

function setStateVariable!(servicer::ScriptServicer, key::String, val::String)
    servicer.stateVariables[key] = val
end


function getStateVariable(servicer::ScriptServicer, key::String)
    try
        val = servicer.stateVariables[key]
    catch e
        e isa KeyError ? throw( ArgumentError("no such state variable: $key") ) : throw(e)
    end
    return val
end


getGlobalShaderName(servicer::ScriptServicer) = return servicer.globalShaderName


function setGlobalShader!(servicer::ScriptServicer, shaderName::String)
    checkInit(servicer)
    servicer.globalShaderName = shaderName
end
