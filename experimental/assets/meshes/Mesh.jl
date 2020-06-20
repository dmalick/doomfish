using GLAbstraction, ModernGL
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("/home/gil/doomfish/experimental/assets/Asset.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")

# XXX I'm not positive whether carrying the MeshName this far down is the way to go or not

mutable struct Mesh <: Asset

    vertexCount::Int
    byteData::Union{IOBuffer, Nothing} # supposedly this'll speed up garbage collection (see "close" function)
                                       # may not be necessary in Julia
    name::MeshName
    filename::String # = name.filename

    unloaded::Bool # = false
end


convert(::Type{String}, mesh::Mesh) = return "Mesh[$(mesh.vertexCount) vertices]($(mesh.filename))"


function Mesh(vertexCount::Int, byteVertexData::IOBuffer, name::MeshName)
    mertics.counters.ramMeshBytesCounter += sizeof(byteVertexData.data)
    mertics.counters.ramMeshesCounter += 1
    return Mesh( vertexCount, byteVertexData, name, name.filename, false )
end


function getByteVertexData(mesh::Mesh)
    checkState( !mesh.unloaded, "Mesh $(mesh.filename) already unloaded" )
    checkState( position(mesh.byteData) == 0, "position(byteData) in Mesh $(mesh.filename) != 0"  )
    return mesh.byteData
end


function close(mesh::Mesh)
    checkState( !mesh.unloaded, "TextureImage $(mesh.filename) already unloaded" )
    freedBytes = sizeof( mesh.byteData.data )
    mesh.byteData = nothing

    metrics.counters.ramMeshBytesCounter-= freedBytes
    metrics.counters.ramMeshesCounter -= 1

    mesh.unloaded = true
end



# TODO EHHHHHHHHHHHHHH
# function uploadMeshGl(mesh::Mesh, boundTarget::Int)
#     glVertexShitshow
# end
