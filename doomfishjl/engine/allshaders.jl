
include("/home/gil/doomfish/doomfishjl/opengl/ShaderProgram.jl")


# since ShaderPrograms can't be instantiated before opengl has initialized, we
# instead define ShaderProxys, which contain all information needed to construct
# a ShaderProgram at runtime. (held in the below Dict `allShaders`)
# ShaderPrograms can then be constructed at runtime as needed, and are cached
# for future use. (see ShaderProgram.jl, ShaderProxy.jl)

allShaders = Dict{ String, ShaderProxy }(
    "default" => ShaderProxy( "default.vert", "default.frag" ),
    "sample"  => ShaderProxy( "sample.vert", "sample.frag" ),
    "altsample" => ShaderProxy( "alt.vert", "sample.frag" ),
    "corners" => ShaderProxy( "corners.vert", "sample.frag" )
)


cachedShaders = Dict{ String, ShaderProgram }()


# if the required ShaderProgram hasn't yet been instantiated, the call to
# getShaderProgram() creates it, then caches it (in above Dict `cachedShaders`).

function getShaderProgram( globalShader::String )
    if !haskey( cachedShaders, globalShader )
        try
            cachedShaders[ globalShader ] = ShaderProgram( allShaders[ globalShader ] )
        catch err
            if err isa KeyError throw( ArgumentError( "Shader '$globalShader' isn't defined in allshaders.jl" ) )
            else throw(err)
            end
        end
    end
    return cachedShaders[ globalShader ]
end
