includepath("doomfishjl/opengl/ShaderProgram.jl")

# WARNING: any of the below calls will cause a crash if opengl hasn't been initialized.
# this file should be 'include'-ed only after initGlfw() has been called in the
# main initialization call.

allShaders = Dict{String, ShaderProgram}(
    "default" => ShaderProgram("default.vert", "default.frag")
    "sample" => ShaderProgram("sample.vert", "sample.frag")
)

cachedShaders = Dict{String, ShaderProgram}()

function getShaderProgram(globalShader::String)
    if !haskey( cachedShaders, globalShader )
        try
            cachedShaders[globalShader] = shaders[globalShader]
        catch e
            if e isa KeyError  throw( ArgumentError("Shader '$globalShader' isn't defined in allshaders.jl") )
            else throw(e)
            end
        end
    end
    return cachedShaders[globalShader]
end
