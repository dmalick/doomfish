include("doomfishjl/engine/allshaders.jl")
include("doomfishjl/engine/DumbshitGlProgram.jl")


vertices = Array{Float32}([-0.5,  0.5, 1.0, 0.0, 0.0,
                            0.5,  0.5, 0.0, 1.0, 0.0,
                            0.5, -0.5, 0.0, 0.0, 1.0,
                           -0.5, -0.5, 1.0, 1.0, 1.0])

elements = Array{UInt32}([0,1,2,2,3,0])



function registerEvent( γ::DumbshitGlProgram, event::Event, callback::Function; input::Union{ Input, Nothing } = nothing )
    @info "registering Event $event with callback $callback $(input != nothing ? "on input $input" : "" )"
    registerEvent!( γ.eventProcessor, event, input = input )
    registerCallback!( γ.logicHandler, event, callback )
end


function resetGlProgram(p::DumbshitGlProgram)
    p.mainWindow = nothing
    GLFW.Terminate()
    return DumbshitGlProgram()
end


function nKeyTest(p::DumbshitGlProgram)

    mouseButtonCallback( window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Int32 ) = ()-> return # mouseInputEvent( p, window, action, button )
    keyCallback( window::GLFW.Window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32 ) = keyInputEvent( p, action, key )

    p.eventProcessor.acceptingRegistrations = true

    registerEvent( p, GlobalEvent(KEY_PRESSED, key = GLFW.KEY_N), ()->( @info "`n` key pressed" ), input = KeyInput(GLFW.PRESS, GLFW.KEY_N) )
    registerEvent( p, GlobalEvent(KEY_RELEASED, key = GLFW.KEY_N), ()->( @info "`n` key released" ), input = KeyInput(GLFW.RELEASE, GLFW.KEY_N) )
    #registerEvent( p, GlobalEvent(KEY_REPEATED, key = GLFW.KEY_N), ()->( @info "`n` key repeated" ), input = KeyInput(GLFW.REPEAT, GLFW.KEY_N) )
    registerCallback!( p.logicHandler, GlobalEvent(LOGIC_FRAME_END), ()-> return )

    p.eventProcessor.acceptingRegistrations = false

    initGlfw()

    p.mainWindow = GlWindow( 800, 600, "window", keyCallback, mouseButtonCallback, false )
    drawData(vertices)

    while !GLFW.WindowShouldClose( p.mainWindow.handle )
        GLFW.SwapBuffers( p.mainWindow.handle )
        GLFW.PollEvents()
        if GLFW.GetKey( p.mainWindow.handle, GLFW.KEY_ESCAPE ) == true
            GLFW.SetWindowShouldClose( p.mainWindow.handle, true )
        end
        processInputs(p)
        dispatchEvents(p)
    end

    GLFW.Terminate()

end


function drawData(vertices)
     vao = getVAO()
     bindVAO(vao)
     vbo = getVBO()
     bindAndLoadVBO( vbo, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices )
     ebo = getVBO()
     bindAndLoadVBO( ebo, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, elements )

     #checkGlError()

     shaderProgram = getShaderProgram( "sample" )
     @info "shaderProgram = $shaderProgram"
     useProgram( shaderProgram )

     # WARNING: these calls to getAttribLocation will fail (or return -1) if they've
     # already been called once in the current Julia REPL session.
     # calling GLFW.Terminate() will not fix this!
     
     positionAttributeLocation = getAttribLocation( "position", shaderProgram )
     @info "typeof( positionAttributeLocation ) = $(typeof(positionAttributeLocation))"
     @info "value of positionAttributeLocation = $positionAttributeLocation"

     @checkGlError vertexAttribPointer( positionAttributeLocation, 2, Float32, false, 5, 0 )

     colorAttributeLocation = getAttribLocation("inColor", shaderProgram)
     @info "typeof( colorAttributeLocation ) = $(typeof(colorAttributeLocation))"
     @info "value of colorAttributeLocation = $colorAttributeLocation"

     @checkGlError vertexAttribPointer( colorAttributeLocation, 3, Float32, false, 5, 2 )


     # triangleColor = getUniformLocation("triangleColor", shaderProgram)
     # glUniform3f(triangleColor, 1.0f0, 1.0f0, 0.0f0)

     #glDrawArrays(GL_POINTS, 0, 207944)
     #glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)
     drawElements( GL_TRIANGLES, 6, UInt32, 0 )

end
