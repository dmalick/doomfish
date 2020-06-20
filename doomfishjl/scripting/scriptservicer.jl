

# FIXME(?): the whole "ScriptServicer" abstraction was meant as an intermediary between java and python.
# wonder whether it's really necessary in its current form
# TODO: in any case, as this file swells, break it up


#=

TODO: EVENT-SPECIFIC CALLBACK REGISTERS GO HERE

XXX or not

=#



# sprite handling

function getSpriteByName(σ::ScriptWorld, spriteName::SpriteName)
    checkInit(σ)
    return getSpriteByName( σ.spriteRegistry, spriteName )
end


function spriteExists(σ::ScriptWorld, spriteName::SpriteName)
    checkInit(σ)
    return spriteExists( σ.spriteRegistry, spriteName )
end

# TODO: this currently just creates a sprite of type DefaultSpriteImpl.
# make it take any.
# in fact, maybe specific implementations should be carried around w/ their templates?
function createSprite(σ::ScriptWorld, templateName::String, spriteName::SpriteName)
    checkInit(σ)
    createSprite( σ.eventProcessor, σ.spriteRegistry, σ.clock, templateName, spriteName )
end


function destroySprite(σ::ScriptWorld, spriteName::SpriteName)
    checkInit(σ)
    destroySprite( σ.eventProcessor, σ.spriteRegistry, spriteName )
end



# SpriteTemplate related functions

function loadSpriteTemplate(σ::ScriptWorld, templateName::String)
    checkInit(σ)
    loadTemplate( σ.spriteRegistry, templateName )
end

getFrameCount(σ::ScriptWorld, templateName::String) = return loadSpriteTemplate( σ, templateName ).frameCount

getNamedMoment(σ::ScriptWorld, templateName::String, momentName::String) = getNamedMoment( σ.spriteRegistry, templateName, momentName )
