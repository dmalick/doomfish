include("includepath.jl")
includepath("doomfishjl/sprite/SpriteRegistry.jl")


# FIXME(?): the whole "ScriptServicer" abstraction was meant as an intermediary between java and python.
# wonder whether it's really necessary in its current form


struct ScriptServicer
    spriteRegistry::SpriteRegistry
    callbacks::Dict{Event, Function}
    stateVariables::Dict{String, String}
    globalShaderName::Union{String, Nothing}
    initializing::Bool
    ScriptServicer(spriteRegistry::SpriteRegistry) = new(spriteRegistry, Dict{Event, Function}(), nothing,
                                                         Dict{String, String}(), true)
end


log(msg::String) = @debug("[ScriptServicer] $msg")


fatal(msg::String) = error("Fatal script error: $msg")


function normalExit()
    @info "Script requested normal exit"
    exit()
end


checkInit(servicer::ScriptServicer) = checkState( !servicer.initializing,
                                            "Only callback registration may be performed during initialization" )


function getSpriteByName(servicer::ScriptServicer, spriteName::SpriteName)
    checkInit(servicer)
    return getSpriteByName(spriteRegistry, spriteName)
end


function spriteExists(servicer::ScriptServicer, spriteName::SpriteName)
    checkInit(servicer)
    return spriteExists( servicer.spriteRegistry, spriteName )
end


function createSprite(servicer::ScriptServicer, templateName::String, spriteName::SpriteName)
    checkInit(servicer)
    createSprite!( servicer.spriteRegistry, templateName, spriteName )
end


function destroySprite(servicer::ScriptServicer, spriteName::SpriteName)
    checkInit(servicer)
    destroySprite!( servicer.spriteRegistry, spriteName)
end


function registerCallback!(servicer::ScriptServicer, event::Event, callback::Function)
    # this should only be callable prior to onBegin, you should not be able to dynamically add callbacks
    # during the game, this would make saving/loading/rewinding/fast forwarding state intractable
    # callbacks should be set up during script initialization, initial sprites should be drawn during onBegin
    # (so if state is saved onBegin can just be skipped and the sprite stack can be restored)
    checkArgument( servicer.spriteRegistry.acceptingCallbacks, "cannot alter callbacks after already begun" )
    checkArgument( !haskey(servicer.callbacks, event), "Callback already registered for $event:
        $(servicer.callbacks[event])" )
    servicer.callbacks[event] = callback
end


#=

TODO: EVENT-SPECIFIC CALLBACK REGISTERS GO HERE

=#


function registerSpriteCallback!(servicer::ScriptServicer, eventType::EventType, spriteName::SpriteName,
                                callback::Function; moment::Union{Int, Nothing}=nothing, key::Union{Int, Nothing}=nothing)
    spriteEvent = SpriteEvent( eventType, spriteName, moment=moment, key=key )
    registerCallback( servicer, spriteEvent, callback )
end


function registerGlobalCallback!(servicer::ScriptServicer, eventType::EventType, callback::Function)
    globalEvent = GlobalEvent( eventType )
    registerCallback( servicer, globalEvent, callback )
end


function loadTemplate(servicer::Servicer, templateName::String)
    checkInit(servicer)
    loadTemplate( servicer.spriteRegistry, templateName )
end


function getFrameCount(servicer::ScriptServicer, templateName::String)
    return getTemplate( servicer.spriteRegistry.spriteTemplateRegistry, templateName ).frameCount

end


getCallback(servicer::ScriptServicer, spriteEvent::SpriteEvent) = return ScriptServicer.callbacks[spriteEvent]



function finishInit!(servicer::ScriptServicer)
    servicer.initializing = false
end


function getCallbacksByType(servicer::ScriptServicer, type::Type{T}) where T <: Event
    return filter( event -> (event.first isa type), servicer.callbacks )
end

getSpriteCallbacks(servicer::ScriptServicer) = getCallbacksByType(servicer, SpriteEvent)
getGlobalCallbacks(servicer::ScriptServicer) = getCallbacksByType(servicer, GlobalEvent)


getNamedMoment(scriptServicer::ScriptServicer, templateName::String, momentName::String) = getNamedMoment(
                                                                                           scriptServicer.spriteRegistry,
                                                                                           templateName, momentName)

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
