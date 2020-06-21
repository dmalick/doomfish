using ModernGL, GLAbstraction
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("ShaderProxy.jl")
include("Shader.jl")



# WARNING: operations on shaders (including calls to any ShaderProgram constructor)
# will fail if opengl hasn't been initialized w/ a call to initGlfw() in GlWindow.jl

mutable struct ShaderProgram
    handle::UInt32
    linked::Bool
    ShaderProgram() = new( glCreateProgram(), false )
end

# constructing a ShaderProgram from a ShaderProxy is our way around the fact that ShaderPrograms
# can't be instantiated before opengl has initialized. ShaderProxys contain all the information
# needed to construct a ShaderProgram but can be pre-defined. (see ShaderProxy.jl, allshaders.jl)

ShaderProgram( proxy::ShaderProxy ) = ShaderProgram( proxy.vert, proxy.frag, proxy.geometry )


# WARNING: as stated before, calls to ShaderProgram() will fail if opengl hasn't been initialized.

function ShaderProgram( vertexShader::String, fragmentShader::String, geometryShader::Union{String, Nothing} = nothing )
    shaderProgram = ShaderProgram()

    attachShader( shaderProgram, loadAndCompileShader( shaderPathBase * vertexShader, GL_VERTEX_SHADER ) )
    attachShader( shaderProgram, loadAndCompileShader( shaderPathBase * fragmentShader, GL_FRAGMENT_SHADER ) )

    if nothing != geometryShader
        attachShader( shaderProgram, loadAndCompileShader( shaderPathBase * geometryShader, GL_GEOMETRY_SHADER ) )
    end

    linkProgram!( shaderProgram )
    return shaderProgram
end


function attachShader( program::ShaderProgram, shader::Shader )
    checkState( !program.linked, "ShaderProgram $(program.handle) already linked" )
    glAttachShader( program.handle, shader.handle )
end


function linkProgram!( program::ShaderProgram )
    checkState( !program.linked, "ShaderProgram $(program.handle) already linked" )
    glLinkProgram( program.handle )
    linkStatus = glGetProgramiv( program.handle, GL_LINK_STATUS )
    #checkState(linkStatus == GL_TRUE, "gLinkProgram failed: $(glGetProgramInfoLog(program.handle))")
    checkState( linkStatus == GL_TRUE, "gLinkProgram failed" )
    program.linked = true
end


function useProgram( program::ShaderProgram )
    checkState( program.linked, "program not linked" )
    glUseProgram( program.handle )
end


getAttribLocation( attribName::String, program::ShaderProgram ) = glGetAttribLocation( program.handle, attribName )

getUniformLocation( uniformName::String, program::ShaderProgram ) = glGetUniformLocation( program.handle, uniformName )
