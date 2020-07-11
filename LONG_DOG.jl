
macro NJGov( body )
    return esc( quote
        $body
        println(""" ____      ____      ______________ """)
        println("""|    \\    |    |    |              |""")
        println("""|     \\   |    |    |     ____     |""")
        println("""|      \\  |    |    |    |    |    |""")
        println("""|       \\ |    |    |    |    |    |""")
        println("""|        \\|    |    |    |    |    |""")
        println("""|    |\\        |    |    |    |    |""")
        println("""|    | \\       |    |    |    |    |""")
        println("""|    |  \\      |    |    |____|    |""")
        println("""|    |   \\     |    |              |""")
        println("""|____|    \\____|    |______________|""")
    end )
end









include("doomfishjl/engine/allshaders.jl")
include("doomfishjl/engine/DumbshitGlProgram.jl")
include("doomfishjl/scripting/onEvent.jl")
includeFiles( "/home/gil/doomfish/doomfishjl/opengl/", "VAO.jl", "VBO.jl" )


vertices = Array{Float32}([-0.5,  0.5, 1.0, 0.0, 0.0,
                            0.5,  0.5, 0.0, 1.0, 0.0,
                            0.5, -0.5, 0.0, 0.0, 1.0,
                           -0.5, -0.5, 1.0, 1.0, 1.0])

elements = Array{UInt32}([0,1,2,2,3,0])


mainGlProgram = DumbshitGlProgram()


function registerEvent( γ::DumbshitGlProgram, event::Event, callback::Function )
    @info "registering Event $event with callback $callback $(event.input != nothing ? "on input $(event.input)" : "" )"
    checkState( γ.eventRegistry != nothing, "cannot register $Event; EventProcessor already initialized" )
    registerEvent!( γ.eventRegistry, event )
    registerCallback!( γ.logicHandler, event, callback )
end


function resetGlProgram( p::DumbshitGlProgram )
    p.mainWindow = nothing
    GLFW.Terminate()
    return DumbshitGlProgram()
end


function nKeyTest( p::DumbshitGlProgram )

    registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_N), ()->( @info "`n` key pressed" ) )
    registerEvent( p, GlobalEvent(KEY_RELEASE, GLFW.KEY_N), ()->( @info "`n` key released" ) )

    registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_S, mods = GLFW.MOD_CONTROL), ()-> display(metrics.timeStats) )
    registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_D, mods = GLFW.MOD_CONTROL), ()-> ( ENV["JULIA_DEBUG"] = Main ) )

    registerEvent( p, GlobalEvent(KEY_PRESS, GLFW.KEY_ESCAPE), ()-> setShouldClose(p.mainWindow, true) )
    #registerEvent( p, GlobalEvent(KEY_REPEATED, key = GLFW.KEY_N), ()->( @info "`n` key repeated" ), input = KeyInput(GLFW.REPEAT, GLFW.KEY_N) )
    registerCallback!( p.logicHandler, GlobalEvent(LOGIC_FRAME_END), ()-> return )

    p.eventProcessor = EventProcessor( p.eventRegistry )
    p.eventRegistry = nothing
    p.logicHandler.acceptingCallbacks = false

end


updateView( p::DumbshitGlProgram ) = drawElements( GL_TRIANGLES, 6, UInt32, 0 )


function createWindow( p::DumbshitGlProgram )

    mouseButtonCallback( window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Int32) = ()-> return # mouseInputEvent( p, window, action, button )
    keyCallback( window::GLFW.Window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32 ) = keyInputEvent( p, action, key, mods )

    initGlfw()

    p.mainWindow = GlWindow( 800, 600, "window", keyCallback, mouseButtonCallback, false )
    drawData(vertices)

    while !GLFW.WindowShouldClose( p.mainWindow.handle )
        loopOnce(p)
    end

    GLFW.Terminate()
    if outputStats display( metrics.timeStats ) end

end


function drawData( vertices )
     vao = VAO()
     bindVAO(vao)
     vbo = VBO()
     bindAndLoadVBO( vbo, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices )
     ebo = VBO()
     bindAndLoadVBO( ebo, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, elements )

     shaderProgram = getShaderProgram( "sample" )
     @info "shaderProgram = $shaderProgram"
     useProgram( shaderProgram )

     # WARNING: these calls to getAttribLocation will fail (return -1) if they've
     # already been called once in the current Julia REPL session.
     # calling GLFW.Terminate() will not fix this!

     positionAttributeLocation = getAttribLocation( "position", shaderProgram )
     @info "typeof( positionAttributeLocation ) = $(typeof(positionAttributeLocation))"
     @info "value of positionAttributeLocation = $positionAttributeLocation"

     @checkGlError vertexAttribPointer( positionAttributeLocation, 2, Float32, false, 5, 0 )
     #vertexAttribPointer( 0, 2, Float32, false, 5, 0 )

     colorAttributeLocation = getAttribLocation("inColor", shaderProgram)
     @info "typeof( colorAttributeLocation ) = $(typeof(colorAttributeLocation))"
     @info "value of colorAttributeLocation = $colorAttributeLocation"

     @checkGlError vertexAttribPointer( colorAttributeLocation, 3, Float32, false, 5, 2 )
     #vertexAttribPointer( 1, 2, Float32, false, 5, 0 )


     # triangleColor = getUniformLocation("triangleColor", shaderProgram)
     # glUniform3f(triangleColor, 1.0f0, 1.0f0, 0.0f0)

     #glDrawArrays(GL_POINTS, 0, 207944)
     #glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)

end
