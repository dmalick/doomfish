using Logging
include("/home/gil/doomfish/doomfishjl/assets/assetnames.jl")
include("AssetCompression.jl")
include("typeIO/MeshIO.jl")
include("typeIO/TextureImageIO.jl")


CACHEABLE_TYPES = ( TEXTURE_IMAGE, MESH, SOUND )


function loadCached(assetName::AssetName)
    filename = assetName.filename
    checkState( assetName.type in CACHEABLE_TYPES, "filename $filename of asset type $(assetName.type) is not a cacheable asset" )

    fileStream = readCached( assetName.cacheKey, filename )

    if nothing != fileStream
        @info "Loading from cache: $filename"

        cachedAsset = @collectstats assetName.loadingStatsName loadFromStream( assetName, fileStream )

        return cachedAsset
    else
        return nothing
    end
end


function loadFromStream(assetName::AssetName, readStream::IOStream)
    headerSize = assetName.headerSize
    seekstart(readStream)
    fileHeader = [ read(readStream, Int) for i in 1:headerSize ]

    expectedDecompressedBytes = *(fileHeader...) * sizeof(Int)
    @info "expectedDecompressedBytes: $expectedDecompressedBytes"

    @assert readStream |> position ==  headerSize * sizeof(Int)
    byteData = decompress(readStream, expectedDecompressedBytes)

    @info "Loaded from cache: $filename"

    return loadFromStream( assetName, byteData )
end


function assetFromFile(assetName::AssetName; readCache::Bool=false, writeCache::Bool=false)
    if readCache
        try
            cached = loadCached( assetName )
            if nothing != cached
                return cached
            end
        catch SystemError
            error( "Fast-load cached asset $assetName exists but loading failed or file was corrupt" )
        end
    end
    asset = assetFromFile( assetName )
    if writeCache
        try
            saveToCache( false, asset )
        catch SystemError
            error( "Failed to write fast-load cached asset $asset" )
        end
    end
    return asset
end
