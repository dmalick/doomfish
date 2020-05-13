include("includepath.jl")
includepath("doomfishjl/sprite/LogicHandler.jl")
includepath("doomfishjl/sprite/SpriteRegistry.jl")

struct ScriptWorld <: LogicHandler
    spriteRegistry::SpriteRegistry
    servicer::ScriptServicer
end





# we just reduced betamax's 19 lines of script loading code to 7.
# I ♥ Julia

function loadScripts(scriptWorld::ScriptWorld, scriptNames::Vector{String})
    scriptWorldVector = [scriptWorld for name in 1:scriptNames]
    map(loadScript, scriptWorldVector, scriptNames)
end
# WARNING: I'm not sure the "include" below will do quite what I want it to
function loadScript(scriptWorld::ScriptWorld,scriptName::String)
    scriptWorld.spriteRegistry.acceptingCallbacks = true
    @info "Evaluating jython script from $scriptName"
    include(scriptName)
    finishInit(scriptWorld.servicer)
    scriptWorld.spriteRegistry.acceptingCallbacks = false
end
