using ModernGL, GLAbstraction
includepath("doomfishjl/globalvars.jl")
include("Shader.jl")



# WARNING: certain operations on shaders will fail if opengl hasn't been
# initialized w/ a call to initGlfw() in GlWindow.jl

mutable struct ShaderProgram
    handle::UInt32
    linked::Bool
    ShaderProgram() = new( glCreateProgram(), false )
end

function ShaderProgram(vertexShader::String, fragmentShader::String)
    shaderProgram = ShaderProgram()
    attachShader( shaderProgram, loadAndCompileShader(shaderPathBase*vertexShader, GL_VERTEX_SHADER) )
    attachShader( shaderProgram, loadAndCompileShader(shaderPathBase*fragmentShader, GL_FRAGMENT_SHADER) )
    linkProgram!( shaderProgram )
    return shaderProgram
end


function attachShader(program::ShaderProgram, shader::Shader)
    checkState(!program.linked, "ShaderProgram $(program.handle) already linked")
    glAttachShader(program.handle, shader.handle)
end


function linkProgram!(program::ShaderProgram)
    checkState(!program.linked, "ShaderProgram $(program.handle) already linked")
    glLinkProgram(program.handle)
    linkStatus = glGetProgramiv(program.handle, GL_LINK_STATUS)
    #checkState(linkStatus == GL_TRUE, "gLinkProgram failed: $(glGetProgramInfoLog(program.handle))")
    checkState(linkStatus == GL_TRUE, "gLinkProgram failed")
    program.linked = true
end


function useProgram(program::ShaderProgram)
    checkState(program.linked, "program not linked")
    glUseProgram(program.handle)
end


function linkAndUse!(program::ShaderProgram)
    linkProgram!(program)
    useProgram(program)
end


getAttribLocation(attribName::String, program::ShaderProgram) = glGetAttribLocation(program.handle, attribName)

getUniformLocation(uniformName::String, program::ShaderProgram) = glGetUniformLocation(program.handle, uniformName)
