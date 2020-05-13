using GLFW, GLAbstraction, ModernGL
import FileIO.load, Images.channelview
include("doomfishtool.jl")
include("ImageLoaderExperimental.jl")


function horse_hell(imageFile)

    img = load(imageFile)

    colorArray = channelview(img)
    channels = size(colorArray)[1]
    height = size(colorArray)[2]
    width = size(colorArray)[3]

    vertexData = getVertexArray(img)


    GLFW.Init()

    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3);
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2);
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE);
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE);
    GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE);

    window = GLFW.CreateWindow(width, height, "HORSEHELL")
    GLFW.MakeContextCurrent(window)


    vao = glGenVertexArrays()
    glBindVertexArray(vao)

    vbo = glGenBuffers()
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW)

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
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, false, (channels + 2)*sizeof(Float32), C_NULL)

    colAttrib = glGetAttribLocation(shaderProgram, "color")
    glEnableVertexAttribArray(colAttrib)
    glVertexAttribPointer(colAttrib, channels, GL_FLOAT, false, (channels + 2)*sizeof(Float32), Ptr{Nothing}(2*sizeof(Float32)))

    glDrawArrays(GL_POINTS, 0, size(vertexData)[1]÷(channels+2))

    while ! GLFW.WindowShouldClose(window)
        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end

    GLFW.Terminate()
end
