include("/home/gil/doomfish/doomfishjl/scripting/scriptservicer.jl") # includes ScriptWorld.jl


globalScriptWorld = nothing

# basic utility functions
log(msg::String) = @debug("[Script] $msg")
fatal(msg::String) = error("Fatal script error: $msg")

function normalExit()
    @info "Script requested normal exit"
    exit()
end

checkInit() = checkInit(globalScriptWorld)
finishInit() = finishInit!(globalScriptWorld)

# sprite handling
getSpriteByName(spriteName::SpriteName) = getSpriteByName( globalScriptWorld, spriteName )
spriteExists(spriteName::SpriteName) = spriteExists( globalScriptWorld, spriteName )
createSprite(templateName::String, spriteName::SpriteName) = createSprite( globalScriptWorld, templateName, spriteName )
destroySprite(spriteName::SpriteName) = destroySprite( globalScriptWorld, spriteName )

# state variable / global shader handling
setStateVariable!(name::String, value::String) = setStateVariable!( globalScriptWorld, name, value )
getStateVariable(name::String) = getStateVariable( globalScriptWorld, name )
getGlobalShaderName() = return globalScriptWorld.globalShaderName
setGlobalShader(shaderName::String) = setGlobalShader!( globalScriptWorld, shaderName )

# Dom: FIXME 13am code
function reboot()
    globalScriptWorld.shouldReboot = true
    @info "Rebooting everything (scheduled)"
end
