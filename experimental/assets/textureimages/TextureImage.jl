using ModernGL, Logging, FileIO
import Base.close, Base.convert
include("/home/gil/doomfish/doomfishjl/assets/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/assets/Asset.jl")
include("/home/gil/doomfish/doomfishjl/opengl/coordinates.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("ColorSample.jl")


mutable struct TextureImage

    width::Int
    height::Int
    channels::Int
    byteData::Union{IOBuffer, Nothing} # supposedly this'll speed up garbage collection (see "close" function)
                                            # may not be necessary in Julia
    name::TextureName
    filename::String # = name.filename

    unloaded::Bool # = false
end

convert(::Type{String}, img::TextureImage) = return "TextureImage[$(img.width) x $(img.height)]($(img.filename))"
# public String toString() {
#         return String.format("TextureImage[%dx%d](%s)", width, height, filename);
#     }

function TextureImage(width::Int, height::Int, channels::Int, bytePixelData::IOBuffer, name::TextureName)
    metrics.counters.ramImageBytesCounter += sizeof(bytePixelData.data)
    metrics.counters.ramTexturesCounter += 1
    return TextureImage( width, height, channels, bytePixelData, name, name.filename, false )
end


function getBytePixelData(textureImage::TextureImage)
    checkState( !textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded" )
    checkState( position(textureImage.byteData) == 0, "position(bytePixelData) in TextureImage $(textureImage.filename) != 0" )

    return textureImage.byteData
end


function close(textureImage::TextureImage)
    checkState( !textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded" )
    freedBytes = sizeof( textureImage.byteData.data )
    textureImage.byteData = nothing

    metrics.counters.ramImageBytesCounter-= freedBytes
    metrics.counters.ramTexturesCounter -= 1

    textureImage.unloaded = true
end


function getTexturePixel(image::TextureImage, coordinate::TextureCoordinate) :: ColorSample
    checkState( !image.unloaded, "TextureImage $(image.filename) already unloaded" )

    x = Int( ceil( coordinate.x * image.width )  )
    y = Int( ceil( coordinate.y * image.height ) )

    return getTexturePixel( image, CartesianIndex(x,y) )
end

function getTexturePixel(image::TextureImage, coordinate::CartesianIndex) :: ColorSample
    checkState( !image.unloaded, "TextureImage $(image.filename) already unloaded" )

    x = coordinate[1]
    y = coordinate[2]

    checkState( x <= image.width, "coordinate $x out of bounds in TextureImage $(image.filename). Max x value is $(image.width)" )
    checkState( y <= image.height, "coordinate $y out of bounds in TextureImage $(image.filename). Max y value is $(image.height)" )

    height = image.height
    channels = image.channels

    pixelStartIndex = ( (x-1) * height + y-1 ) * channels * sizeof(Int)
    seek( image.byteData, pixelStartIndex )

    pixel = [ read( image.byteData, Int ) for i in 1:channels ]
    colorSample = ColorSample( pixel... )

    @info "Pixel at $x x $y is $colorSample (from $(image.filename))"

    seekstart( image.byteData )
    return colorSample

end


# retooled this one to account for variable channels.
# WARNING I may not know what I'm doing
# WARNING there is also the possibility that the pixel byte data below needs to represent Float32s, not Ints
function uploadTextureImageGl( textureImage::TextureImage, boundTarget::Int )
    checkState( !textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded" )
    checkState( textureImage.channels == 4 || textureImage.channels == 3, "TextureImage $(textureImage.filename) has invalid number of channels ($(textureImage.channels))" )
    @collectstats TEXTURE_UPLOADS glTexImage2D(
                 boundTarget,
                 textureImage.channels == 4 ? GL_RGBA8 : GL_RGB8, # total guess that this is right. it may shit the bed
                 textureImage.width,
                 textureImage.height,
                 0,
                 textureImage.channels == 4 ? GL_RGBA : GL_RGB, # ditto
                 GL_UNSIGNED_BYTE,
                 textureImage.byteData.data
                 )
end

getByteCount(textureImage::TextureImage) = sizeof(textureImage.byteData.data)
