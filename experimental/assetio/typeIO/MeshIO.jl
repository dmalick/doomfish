using Logging
using MeshIO
import FileIO.load
include("/home/gil/doomfish/experimental/assets/meshes/Mesh.jl")
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("/home/gil/doomfish/experimental/assetio/AssetCompression.jl")


function assetFromFile(meshName::MeshName)
    filename = meshName.filename
    try
        mesh = load(filename)
    catch e
        error("Mesh file $filename failed to load")
    end

    # values in the vector below are grouped in threes, i.e. the first 3 values represent
    # one vertex, the next three values represent the next vertex, etc.
    # this representation is simpler than the analogous vector in imageIO.jl b/c the order
    # of the vertices doesn't really matter.
    # WARNING: it may be that there are performance ramifications for what I just said.
    mesh = vcat( Vector.([ mesh[i][j] for i in 1:length(mesh) for j in 1:3 ])... ) # shut up
    vertexCount = length(mesh)

    @info "loaded mesh from $filename ($vertexCount vertices)"

    byteVertexData = IOBuffer()
    write( byteVertexData, mesh )

    return Mesh( vertexCount, byteVertexData, filename )
end


function loadFromStream(meshName::MeshName, fileHeader::Vector{Int}, bytePixelData::IOBuffer)
    vertexCount = fileHeader[1]

    # TODO not sure what an appropriate upper-bound vertexCount is, but we should have one.
    checkState( vertexCount > 0, "bad vertex count: $vertexCount" )

    return Mesh( vertexCount, byteData, meshName, false)
end


function saveToCache(overwrite::Bool, mesh::Mesh)
    checkState(!mesh.unloaded)
    # betamax surrounds the following in a try block
    # try {
        fileStream = writeCached( overwrite, meshCacheKey, mesh.filename )
        @info "Saving to cache: $(mesh.filename)"
        # betamax: FIXME write original filename as a safety check

        write( fileStream, mesh.vertexCount )

        compressedVertexData = compress( mesh.byteData )
        checkState( sizeof( compressedVertexData.data ) > 0, "Vertex data compression failed: size of compressedVertexData not > 0" )

        write( fileStream, compressedVertexData ) |> println

        @info "savedToCache: $(mesh.filename)"
    # }
end
