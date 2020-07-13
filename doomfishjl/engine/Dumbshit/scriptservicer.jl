include("/home/gil/doomfish/doomfishjl/eventhandling/event/Event.jl")
include("AbstractDumbshitGlProgram.jl")


# we keep this separate from the GlProgram b/c it prevents us from having to re-import
# the whole GlProgram every time a script imports scriptservicer.jl
function registerEvent( γ::AbstractDumbshitGlProgram, event::Event, callback::Function )
    @info "registering Event $event with callback $callback $(event.input != nothing ? "on input $(event.input)" : "" )"
    checkState( γ.eventRegistry != nothing, "cannot register $Event; EventProcessor already initialized" )
    registerEvent!( γ.eventRegistry, event )
    registerCallback!( γ.logicHandler, event, callback )
end


# functions/macros in scriptservicer.jl refer directly to the global variable mainGlProgram,
# rather than take a GlProgram as an argument. This is purely for convenience, and scripts
# need not be constructed solely from the functions defined here.
# calls to macros/functions in scriptservicer.jl should not be made before mainGlProgram
# is initialized.

global mainGlProgram

# @on and @onLogicFrameEnd are cleaner ways to make the necessary calls to registerEvent
# and registerCallback!, and refer directly to mainGlProgram.

macro on( event, callback )
    checkState( argIs(event, Event) || argIs(event, :call), "1st argument to @on must be an Event (got $event)"  )
    checkState( callback isa Expr && callback.head in ( :call, :macrocall, :block, :-> ),
                "2nd argument to @on must be a function call, macro call, or begin block (got $callback)" )
    return :( registerEvent( mainGlProgram, $event, ()->$callback ) )
end


macro onLogicFrameEnd( callback )
    checkState( callback isa Expr && callback.head in ( :call, :macrocall, :block, :-> ),
                "argument to @onLogicFrameEnd must be a function call, macro call, or begin block (got $callback)" )
    return :( registerCallback!( mainGlProgram.logicHandler, GlobalEvent(LOGIC_FRAME_END), ()->$callback ) )
end


# scripts should (mostly) be constructed from the following, but are not in any way required to be.
# all of these functions refer directly to mainGlProgram.

checkInit( init::Bool=true ) = checkState( init == (mainGlProgram isa GlProgramBase && mainGlProgram.mainWindow != nothing && mainGlProgram.eventProcessor != nothing ),
"main program (global var `mainGlProgram`) $( init ? "not set or fully initialized" : "already initialized" )." )


function getCursorPosition( ;window::GlWindow = mainGlProgram.mainWindow, coordType::Type{T} = TextureCoordinate )::GlCoordinate where T <: GlCoordinate
    checkInit()
    return getCursorPosition( mainGlProgram.mainWindow, coordType )
end
