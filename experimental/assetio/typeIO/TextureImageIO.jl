using Logging
import FileIO.load, Images.channelview
include("/home/gil/doomfish/doomfishjl/assets/textureimages/TextureImage.jl")
include("/home/gil/doomfish/doomfishjl/assets/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/assetio/AssetCompression.jl")


function assetFromFile(textureName::TextureName)
    filename = textureName.filename
    try
        image = channelview( load(filename) )
    catch SystemError
        error("image file $filename failed to load")
    end
    width = size(image)[3]
    height = size(image)[2]
    channels = size(image)[1]

    # thank you julia
    image = convert.( Int, image.*255 )

    # converts the ridiculous 3D channelview matrix into a straight vector of Ints,
    # each representing the value of one channel in one pixel.
    # the pixels are grouped by y-value first, then x.
    # i.e., three or four values (depending on channels) make up a pixel.
    # the first `height` groups of them represent the coordinates (1,1) to (1,height),
    # the next `height` groups of them represent the coordinates (2,1) to (2,height),
    # and so on. the array contains a total of (width * height * channels) Ints, and
    # requires (width * height * channels * sizeof(Int)) bytes in its uncompressed state.
    image = vcat( vec( [ image[:, height - y + 1, x] for y in 1:height, x in 1:width ] )... )

    @info "Loaded $channels-channel image from $filename (size $width x $height)"

    bytePixelData = IOBuffer()
    write( bytePixelData, image )

    return TextureImage( width, height, channels, bytePixelData, textureName )
end


function loadfromStream(textureName::TextureName, fileHeader::Vector{Int}, bytePixelData::IOBuffer)
    width = fileHeader[1]
    height = fileHeader[2]
    channels = fileHeader[3]

    # below limits are arbitrary. per betamax, 250 Mpx will do for now.
    checkState( width > 0 && height > 0 && width < 16384 && height < 16384, "bad image size $width x $height" )

    # WARNING: betamax returns an Optional here. Uncertain whether we'll need to account
    # for this with Union{TextureImage, Nothing} or not.
    return TextureImage( width, height, channels, byteData, textureName )
end


function saveToCache(overwrite::Bool, image::TextureImage)
    checkState(!image.unloaded)
    # betamax surrounds the following in a try block
    # try {
        fileStream = writeCached( overwrite, textureCacheKey, image.filename )
        @info "Saving to cache: $(image.filename)"
        # betamax: FIXME write original filename as a safety check

        write( fileStream, image.width )
        write( fileStream, image.height )
        write( fileStream, image.channels )

        compressedPixelData = compress( image.byteData )
        @assert sizeof( compressedPixelData.data ) > 0

        write( fileStream, compressedPixelData ) |> println

        @info "savedToCache: $(image.filename)"
    # }
end
