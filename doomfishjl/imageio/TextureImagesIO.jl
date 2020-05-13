using Logging
import FileIO.load, Images.channelview
include("includepath.jl")
includepath("doomfishjl/globalvars.jl")
includepath("doomfishjl/assetnames.jl")
include("TextureCompression.jl")
include("TextureImage.jl")
includepath("doomfishjl/doomfishtool.jl")

# WARNING I don't really know what the hell this is for
CACHE_KEY = "TextureImages#textureImageFromFile;lz4"

function loadCached(filename::String)
    fileStream = readCached( CACHE_KEY, filename )
    if nothing != fileStream
        @info "Loading from cache: $filename"
        cachedImageWithLoadTimeStats = @timed loadFromStream( filename, fileStream )
        updateTimedStats!( metrics, CACHED_IMAGE_LOADING, cachedImageWithLoadTimeStats... )
        return cachedImageWithLoadTimeStats[1]
    else
        return nothing
    end
end

# WARNING: the original betamax code does not allow multiple channel values for sprites,
# rather, all sprites were required to have 4 channels. We want to allow for an
# arbitrary number of channels, and have retooled for this.
# HOWEVER, I'm not entirely certain I hit everything. There could be fixed-channel
# code still out there, and it could lead to some nasty bugs.

function loadFromStream(filename::String, readStream::IOStream)
    headerSize = 3  # width, height, channels
    seekstart(readStream)
    fileHeader = [ read(readStream, Int) for i in 1:headerSize ]

    width = fileHeader[1]
    height = fileHeader[2]
    channels = fileHeader[3]

    # below limits are arbitrary. per betamax, 250 Mpx will do for now.
    checkState( width > 0 && height > 0 && width < 16384 && height < 16384, "bad image size $width x $height" )

    expectedDecompressedBytes = width * height * channels * sizeof(Int)
    @info "expectedDecompressedBytes: $expectedDecompressedBytes"

    @assert readStream |> position ==  3 * sizeof(Int)
    bytePixelData = decompress(readStream, expectedDecompressedBytes)

    @info "Loaded from cache: $filename"

    # WARNING: betamax returns an Optional here. Uncertain whether we'll need to account
    # for this with Union{TextureImage, Nothing} or not.
    return TextureImage( width, height, channels, bytePixelData, filename, false )

end

# betamax calls this function fromRgbaFile. we want to allow for other formats, and we name it as such
function textureImageFromFile(textureName::TextureName; readCache::Bool=false, writeCache::Bool=false)
    if readCache
        try
            cached = loadCached( textureName.filename )
            if nothing != cached
                return cached
            end
        catch SystemError
            error( "Fast-load cached texture exists but loading failed or file was corrupt" )
        end
    end
    textureImage = TextureImageFromFile( textureName.filename )
    if writeCache
        try
            saveToCache( false, textureImage )
        catch SystemError
            error( "Failed to write fast-load cached texture" )
        end
    end
    return textureImage
end


# FYI
# valueVector[((x-1)*height+y)*channels-(channels-1):((x-1)*height+y)*channels] == pixelVector[(x-1)*height+y] == pixelMatrix[x,y]
# where valueVector is straight R, G, B, and A (or however many channels) integer values,
# pixelVector is a vector of [R,G,B,A...] arrays w/ number of elements equal to number of channels,
# pixelMatrix is a matrix representation of the image, w/ [R,G,B,A...] groups representing pixels at any given x,y coordinate
# the matrix indexing is consistent w/ TextureCoordinates

# I don't really like naming these the same thing but betamax does it, we can for now
function textureImageFromFile(filename::String)
    try
        image = channelview( load(filename) )
    catch SystemError
        error("image file failed to load")
    end
    width = size(image)[3]
    height = size(image)[2]
    channels = size(image)[1]

    # thank you julia
    image = convert.( Int, image.*255 )

    # converts the ridiculous 3D channelview matrix into a straight array of Ints,
    # each representing the value of one channel in one pixel
    # the pixels are grouped by y-value first, then x
    # i.e., three or four values (depending on channels) make up a pixel.
    # the first `height` groups of them represent the coordinates (1,1) to (1,height)
    # the next `height` groups of them represent the coordinates (2,1) to (2,height),
    # and so on. the array contains a total of (width * height * channels) Ints, and
    # requires (width * height * channels * sizeof(Int)) bytes in its uncompressed state.
    image = vcat( vec( [ image[:, height - y + 1, x] for y in 1:height, x in 1:width ] )... )

    @info "Loaded $channels-channel image from $filename (size $width x $height)"

    bytePixelData = IOBuffer()
    write( bytePixelData, image )

    return TextureImage( width, height, channels, bytePixelData, filename, false )
end

cachedFilename(textureName::TextureName) = cachedFilename( CACHE_KEY, textureName.filename )

function saveToCache(overwrite::Bool, image::TextureImage)
    checkState(!image.unloaded)
    # betamax surrounds the following in a try block
    # try {
        fileStream = writeCached( overwrite, CACHE_KEY, image.filename )
        @info "Saving to cache: $(image.filename)"
        # betamax: FIXME write original filename as a safety check

        write( fileStream, image.width )
        write( fileStream, image.height )
        write( fileStream, image.channels )

        compressedPixelData = compress( image.bytePixelData )
        @assert sizeof( compressedPixelData.data ) > 0

        write( fileStream, compressedPixelData ) |> println

        @info "savedToCache: $(image.filename)"
    # }
end
