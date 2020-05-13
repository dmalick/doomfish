using ModernGL, Logging, FileIO
import Base.close, Base.convert
includepath("doomfishjl/globalvars.jl")
includepath("doomfishjl/doomfishtool.jl")
includepath("doomfishjl/opengl/coordinates.jl")
include("ColorSample.jl")


mutable struct TextureImage

    width::Int
    height::Int
    channels::Int
    bytePixelData::Union{IOBuffer, Nothing} # supposedly this'll speed up garbage collection (see "close" function)
                                            # may not be necessary in Julia
    filename::String

    unloaded::Bool # = false

end

convert(::Type{String}, img::TextureImage) = return "TextureImage[$(img.width) x $(img.height)]($(img.filename))"
# public String toString() {
#         return String.format("TextureImage[%dx%d](%s)", width, height, filename);
#     }

function TextureImage(;width::Int, height::Int, channels::Int, bytePixelData::IOBuffer, filename::String)
    mertics.counters.ramImageBytesCounter += sizeof(bytePixelData.data)
    mertics.counters.ramTexturesCounter += 1
    return TextureImage( width, height, channels, bytePixelData, filename, false )
end


function getBytePixelData(textureImage::TextureImage)
    checkState( !textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded" )
    checkState( position(textureImage.bytePixelData) == 0, "position(bytePixelData) in TextureImage $(textureImage.filename) != 0" )

    return textureImage.bytePixelData
end


function close(textureImage::TextureImage)
    checkState( !textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded" )
    freedBytes = sizeof( textureImage.bytePixelData.data )
    textureImage.bytePixelData = nothing

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
    seek( image.bytePixelData, pixelStartIndex )

    pixel = [ read( image.bytePixelData, Int ) for i in 1:channels ]
    colorSample = ColorSample( pixel... )

    @info "Pixel at $x x $y is $colorSample (from $(image.filename))"

    seekstart( image.bytePixelData )
    return colorSample

end


# retooled this one to account for variable channels.
# WARNING I may not know what I'm doing
# WARNING there is also the possibility that the pixel byte data below needs to represent Float32s, not Ints
function uploadTextureImageGl( textureImage::TextureImage, boundTarget::Int )
    checkState( !textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded" )
    checkState( textureImage.channels == 4 || textureImage.channels == 3, "TextureImage $(textureImage.filename) has invalid number of channels ($(textureImage.channels))" )
    textureUploadStats = @timed glTexImage2D(
                 boundTarget,
                 textureImage.channels == 4 ? GL_RGBA8 : GL_RGB8, # total guess that this is right. it may shit the bed
                 textureImage.width,
                 textureImage.height,
                 0,
                 textureImage.channels == 4 ? GL_RGBA : GL_RGB, # ditto
                 GL_UNSIGNED_BYTE,
                 textureImage.bytePixelData.data
                 )
    updateTimedStats!( metrics, TEXTURE_UPLOADS, textureUploadStats )
end

getByteCount(textureImage::TextureImage) = sizeof(textureImage.bytePixelData.data)
