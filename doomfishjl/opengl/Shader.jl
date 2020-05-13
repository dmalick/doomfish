using ModernGL, GLAbstraction
includepath("doomfishjl/doomfishtool.jl")


# WARNING: certain operations on shaders will fail if opengl hasn't been
# initialized w/ a call to initGlfw() in GlWindow.jl

struct Shader
     handle::UInt32
end

function loadAndCompileShader(filename::String, shaderType::UInt32)
    shaderSource::String = loadResource(filename)
    shader::UInt32 = glCreateShader(shaderType)
    glShaderSource(shader, shaderSource)
    glCompileShader(shader)

    status = glGetShaderiv(shader, GL_COMPILE_STATUS)
    @info "glShaderiv(shader, GL_COMPILE_STATUS) return val = $status"
    checkState(status==GL_TRUE, "shader $(filename) failed to compile")

    return Shader(shader)
end
