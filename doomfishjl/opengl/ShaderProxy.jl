

# calls to ShaderProgram constructors will fail if called before opengl has been
# initialized (likely with a call to initGlfw() in GlWindow.jl).

# ShaderProxys contain all data necessary to create a ShaderProgram but can be
# defined at compiletime. (see ShaderProgram.jl, allshaders.jl)

struct ShaderProxy
    vertex::String
    fragment::String
    geometry::Union{ String, Nothing }
end

ShaderProxy( vertex::String, fragment::String ) = ShaderProxy( vertex, fragment, nothing )
