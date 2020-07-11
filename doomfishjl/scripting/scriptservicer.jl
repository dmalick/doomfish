include("/home/gil/doomfish/doomfishjl/engine/GlProgramBase.jl")
includeDir("/home/gil/doomfish/doomfishjl/eventhandling/event/events/")
include("onEvent.jl")


function loadScripts( p::GlProgramBase )

    p.logicHandler.acceptingCallbacks = true

    includeFiles( resourcePathBase * "scripts" )

    p.logicHandler.acceptingCallbacks = false

end



checkInit( init::Bool=true ) = checkState( init == (mainGlProgram isa GlProgramBase && mainGlProgram.mainWindow && mainGlProgram.eventProcessor != nothing ),
"main program (global var `mainGlProgram`) $( init ? "not set or fully initialized" : "already initialized" )." )


function getCursorPosition( ;window::GlWindow = mainGlProgram.mainWindow, coordType::Type{T} = TextureCoordinate )::GlCoordinate where T <: GlCoordinate
    checkInit()
    return getCursorPosition( mainGlProgram.mainWindow, coordType )
end
