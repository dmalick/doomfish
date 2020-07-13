include("DumbshitGlProgram.jl")
include("scriptservicer.jl")

global mainGlProgram = DumbshitGlProgram()

# scriptloading step and main game running step must be kept separate,
# otherwise a weird error occurs having to do w/ methods being too new(?)
# basically, as long as we don't create event callbacks in one sub-scope of
# a function and call them in a different sub-scope (even if they both
# reference the same global vars), we're fine. Probably way off here but
# this works, so fuck it.

@collectstats SCRIPT_LOADING includeDir( resourcePathBase * "scripts/" )
runGlProgram( mainGlProgram )

    
