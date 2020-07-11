using GLFW, GLAbstraction, ModernGL

include("opengl/VAO.jl")
include("opengl/VBO.jl" )
include("opengl/ShaderProgram.jl")
include("doomfishtool.jl")

SAMPLEVERTEXDATA = [0f0, 0.5f0, 0.5f0, -0.5f0, -0.5f0, -0.5f0]

vertices = Array{Float32}([-0.5,  0.5, 1.0, 0.0, 0.0,
                            0.5,  0.5, 0.0, 1.0, 0.0,
                            0.5, -0.5, 0.0, 0.0, 1.0,
                           -0.5, -0.5, 1.0, 1.0, 1.0])

elements = Array{UInt32}([0,1,2,2,3,0])

pixels = Array{Float32}([0.0, 0.0, 0.0,  1.0, 1.0, 1.0,
                         1.0, 1.0, 1.0,  0.0, 0.0, 0.0])

function GlSample(width, height, title, vertices)
    GLFW.Init()

    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, true)

    GLFW.WindowHint(GLFW.RESIZABLE, false)

    window = GLFW.CreateWindow(width, height, title)
    GLFW.MakeContextCurrent(window)

    drawData(vertices, elements)

    while !GLFW.WindowShouldClose(window)
        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
        if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == true
            GLFW.SetWindowShouldClose(window, true)
        end
    end

    GLFW.Terminate()

end

GlSample() = GlSample( 800, 600, "sample", vertices )

function drawData(vertices, elements)
     vao = VAO()
     bindVAO(vao)
     vbo = VBO()
     bindAndLoadVBO(vbo, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices)
     ebo = VBO()
     bindAndLoadVBO(ebo, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, elements)
     tex = glGenTextures()
     glBindTexture(GL_TEXTURE_2D, tex)

     vertexShader = loadAndCompileShader(shaderPathBase*"sample.vert", GL_VERTEX_SHADER)
     fragmentShader = loadAndCompileShader(shaderPathBase*"sample.frag", GL_FRAGMENT_SHADER)
     shaderProgram = ShaderProgram()

     attachShader(shaderProgram, vertexShader)
     attachShader(shaderProgram, fragmentShader)
     linkProgram!(shaderProgram)
     useProgram(shaderProgram)

     positionAttributeLocation = getAttribLocation("position", shaderProgram)
     vertexAttribPointer(positionAttributeLocation, 2, Float32, false, 5, 0)

     colorAttributeLocation = getAttribLocation("color", shaderProgram)
     vertexAttribPointer(colorAttributeLocation, 3, Float32, false, 5, 2)


     # triangleColor = getUniformLocation("triangleColor", shaderProgram)
     # glUniform3f(triangleColor, 1.0f0, 1.0f0, 0.0f0)

     #glDrawArrays(GL_POINTS, 0, 207944)
     #glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)
     drawElements(GL_TRIANGLES, 6, UInt32, 0)

end
