include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("onEvent.jl")


function loadScripts()

    glProgram.eventProcessor.acceptingRegistrations = true
    glProgram.logicHandler.acceptingCallbacks = true

    includeFiles( resourcePathBase * "scripts" )

    glProgram.eventProcessor.acceptingRegistrations = false
    glProgram.logicHandler.acceptingCallbacks = false

end
