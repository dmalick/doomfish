using GLFW, GLAbstraction, ModernGL
include("doomfishtool.jl")

GLFW.Init()

GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3);
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2);
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE);
GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE);
GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE);

window = GLFW.CreateWindow(800, 600, "D")
GLFW.MakeContextCurrent(window)

vertices = [0.0f0,  0.5f0, #1.0f0, 0.0f0, 0.0f0,
            0.5f0, -0.5f0, #0.0f0, 1.0f0, 0.0f0,
           -0.5f0, -0.5f0] #0.0f0, 0.0f0, 1.0f0]

# colors = [1.0f0, 0.0f0, 0.0f0,
#           0.0f0, 1.0f0, 0.0f0,
#           0.0f0, 0.0f0, 1.0f0]


vao = glGenVertexArrays()
glBindVertexArray(vao)

vbo = glGenBuffers()
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

vertexShader = glCreateShader(GL_VERTEX_SHADER)
vertexSource = read("/home/gil/.atom/doomfishjl/shaders/sample.vert", String)
glShaderSource(vertexShader, vertexSource)
glCompileShader(vertexShader)
checkState(glGetShaderiv(vertexShader, GL_COMPILE_STATUS) == GL_TRUE, "vert shader did not compile")

fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
fragmentSource = read("/home/gil/.atom/doomfishjl/shaders/sample.frag", String)
glShaderSource(fragmentShader, fragmentSource)
glCompileShader(fragmentShader)
checkState(glGetShaderiv(fragmentShader, GL_COMPILE_STATUS) == GL_TRUE, "frag shader did not compile")

shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)

glBindFragDataLocation(shaderProgram, 0, "outColor")

glLinkProgram(shaderProgram)
glUseProgram(shaderProgram)

posAttrib = glGetAttribLocation(shaderProgram, "position")
glEnableVertexAttribArray(posAttrib)
glVertexAttribPointer(posAttrib, 2, GL_FLOAT, false, 0, C_NULL)

# colAttrib = glGetAttribLocation(shaderProgram, "inColor")
# glEnableVertexAttribArray(colAttrib)
# glVertexAttribPointer(colAttrib, 3, GL_FLOAT, false, 5*sizeof(Float32), pointer("(void*)(2*sizeof(float))"))

triangleColor = glGetUniformLocation(shaderProgram, "triangleColor")
glUniform3f(triangleColor, 1.0f0, 0.0f0, 0.0f0)

glDrawArrays(GL_TRIANGLES, 0, 3)

while ! GLFW.WindowShouldClose(window)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
end

GLFW.Terminate()
