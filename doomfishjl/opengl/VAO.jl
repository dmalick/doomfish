using ModernGL, GLAbstraction
include("/home/gil/doomfish/doomfishjl/engine/allshaders.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("typeEquivalencies.jl")


struct VAO
    handle::UInt32
end


function getVAO()
    return VAO(glGenVertexArrays())
end


# some very important stuff going on below. see https://open.gl/drawing
function vertexAttribPointer_raw( attribLocation, size, glType, normalized, stride_in_bytes, offset_in_bytes=0 )
    glEnableVertexAttribArray( attribLocation )
    glVertexAttribPointer( attribLocation, size, glType, normalized, stride_in_bytes, Ptr{Nothing}(offset_in_bytes) )
end


function vertexAttribPointer( attribLocation, size, type, normalized, stride, offset=0 )
    checkState( haskey(typeEquivalencies, type), "$type not found in typeEquivalencies; use function vertexAttribPointer_raw" )
    vertexAttribPointer_raw( attribLocation, size, typeEquivalencies[type], normalized, stride * sizeof(type), offset * sizeof(type) )
end


function vertexAttribPointer( shaderName::String, attribName::String, size, type, normalized, stride, offset=0 )
    attribLocation = glGetAttribLocation( attribName, getShaderProgram(shaderName) )
    vertexAttribPointer( attribLocation, size, type, normalized, stride, offset )
end


function bindVAO(vao::VAO)
        glBindVertexArray(vao.handle)
end
