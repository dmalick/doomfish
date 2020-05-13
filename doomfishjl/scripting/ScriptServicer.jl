


struct ScriptServicer
    spriteRegistry::SpriteRegistry
    callbacks::Dict{Event, Function}
    initializing::Bool
    ScriptServicer(spriteRegistry::SpriteRegistry) = new(spriteRegistry, Dict{SpriteEvent, Function}(),
                                                         Dict{EventType, Function}(), true)
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


function registerCallback(servicer::ScriptServicer, event::Event, callback::Function)
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


function registerSpriteCallback(servicer::ScriptServicer, eventType::EventType, spriteName::SpriteName,
                                callback::Function; moment::Union{Int, Nothing}=nothing, key::Union{Int, Nothing}=nothing)
    spriteEvent = SpriteEvent( eventType, spriteName, moment=moment, key=key )
    registerCallback( servicer, spriteEvent, callback )
end


function registerGlobalCallback(servicer::Servicer, eventType::EventType, callback::Function)
    globalEvent = GlobalEvent( eventType )
    registerCallback( servicer, globalEvent, callback )
end
