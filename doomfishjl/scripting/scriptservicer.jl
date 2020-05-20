include("/home/gil/doomfish/doomfishjl/eventhandling/ScriptWorld.jl")


# FIXME(?): the whole "ScriptServicer" abstraction was meant as an intermediary between java and python.
# wonder whether it's really necessary in its current form
# TODO: in any case, as this file swells, break it up


#=

TODO: EVENT-SPECIFIC CALLBACK REGISTERS GO HERE

or not

=#



# sprite handling

function getSpriteByName(σ::ScriptWorld, spriteName::SpriteName)
    checkInit(σ)
    return getSpriteByName( σ.eventProcessor, spriteName )
end


function spriteExists(σ::ScriptWorld, spriteName::SpriteName)
    checkInit(σ)
    return spriteExists( σ.eventProcessor, spriteName )
end


function createSprite(σ::ScriptWorld, templateName::String, spriteName::SpriteName)
    checkInit(σ)
    createSprite( σ.eventProcessor, templateName, spriteName )
end


function destroySprite(σ::ScriptWorld, spriteName::SpriteName)
    checkInit(σ)
    destroySprite( σ.eventProcessor, spriteName)
end



# SpriteTemplate related functions

function loadSpriteTemplate(σ::ScriptWorld, templateName::String)
    checkInit(σ)
    loadSpriteTemplate( σ.eventProcessor, templateName )
end

getFrameCount(σ::ScriptWorld, templateName::String) = return getSpriteTemplate( σ.eventProcessor, templateName ).frameCount

getNamedMoment(σ::ScriptWorld, templateName::String, momentName::String) = getNamedMoment(σ.eventProcessor, templateName, momentName)
