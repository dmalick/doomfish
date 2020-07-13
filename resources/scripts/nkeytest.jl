include("/home/gil/doomfish/doomfishjl/engine/Dumbshit/scriptservicer.jl")


# rightUni = getUniformLocation( "right", mainGlProgram.globalShader )
# registerEvent( mainGlProgram, KeyPress( GLFW.KEY_RIGHT ), ()-> glUniform1f( rightUni, 0.25f0 ) )
# registerEvent( mainGlProgram, KeyRelease( GLFW.KEY_RIGHT ), ()-> glUniform1f( rightUni, 0.0f0 ) )
#
# downUni = getUniformLocation( "down", mainGlProgram.globalShader )
# registerEvent( mainGlProgram, KeyPress( GLFW.KEY_DOWN ), ()-> glUniform1f( downUni, -0.25f0 ) )
# registerEvent( mainGlProgram, KeyRelease( GLFW.KEY_DOWN ), ()-> glUniform1f( downUni, 0.0f0 ) )
#
# leftUni = getUniformLocation( "left", mainGlProgram.globalShader )
# registerEvent( mainGlProgram, KeyPress( GLFW.KEY_LEFT ), ()-> glUniform1f( leftUni, -0.25f0 ) )
# registerEvent( mainGlProgram, KeyRelease( GLFW.KEY_LEFT ), ()-> glUniform1f( leftUni, 0.0f0 ) )


@on KeyPress( key"up" ) glUniform1f( getUniformLocation( "up", mainGlProgram.globalShader ), 0.25f0 )
@on KeyRelease( key"up" ) glUniform1f( getUniformLocation( "up", mainGlProgram.globalShader ), 0.0f0 )

@on KeyPress( key"right" ) glUniform1f( getUniformLocation( "right", mainGlProgram.globalShader ), 0.25f0 )
@on KeyRelease( key"right" ) glUniform1f( getUniformLocation( "right", mainGlProgram.globalShader ), 0.0f0 )

@on KeyPress( key"down" ) glUniform1f( getUniformLocation( "down", mainGlProgram.globalShader ), -0.25f0 )
@on KeyRelease( key"down" ) glUniform1f( getUniformLocation( "down", mainGlProgram.globalShader ), 0.0f0 )

@on KeyPress( key"left" ) glUniform1f( getUniformLocation( "left", mainGlProgram.globalShader ), -0.25f0 )
@on KeyRelease( key"left" ) glUniform1f( getUniformLocation( "left", mainGlProgram.globalShader ), 0.0f0 )

@on KeyPress( key"n" ) @info "`n` key pressed"
@on KeyRelease( key"n" ) @info "`n` key released"

@on KeyPress( keyPress"ctrl s" ) display( metrics.timeStats )
@on KeyPress( keyPress"ctrl d" ) toggleDebug()

@on KeyPress( key"escape" ) setShouldClose( mainGlProgram.mainWindow, true )
