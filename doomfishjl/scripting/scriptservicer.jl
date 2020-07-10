include("/home/gil/doomfish/doomfishjl/engine/GlProgramBase.jl")
includeDir("/home/gil/doomfish/doomfishjl/eventhandling/event/events/")
include("onEvent.jl")


checkInit( init::Bool=true ) = checkState( init === (glProgram isa GlProgramBase && glProgram.mainWindow && glProgram.eventProcessor != nothing ),
    "main program (global var `glProgram`) $( init ? "not set or fully initialized" : "already initialized" )." )


function loadScripts( p::GlProgramBase )

    p.logicHandler.acceptingCallbacks = true

    includeFiles( resourcePathBase * "scripts" )

    p.logicHandler.acceptingCallbacks = false

end


function getCursorPosition( ;coordType::Type{T} = TextureCoordinate )::GlCoordinate where T <: GlCoordinate
    checkInit()
    return getCursorPosition( glProgram.mainWindow, coordType )
end
