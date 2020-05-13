using ModernGL, Logging
import Base.close
include("/home/gil/.atom/doomfishjl/globalvars.jl")
include("/home/gil/.atom/doomfishjl/doomfishtool.jl")
include("/home/gil/.atom/doomfishjl/opengl/coordinates.jl")
include("colorsample.jl")
include("TextureImagesIO.jl")
include("JlImage.jl")

struct TextureImage{T<:JlImage}
    filename::String

    width::Int
    height::Int
    channels::Int

    image::T

    unloaded::Bool
end

function TextureImage(;image::JlImage, filename::String)
    metrics.ramImageBytesCounter += sizeof(bytePixelData)
    metrics.ramTexturesCounter += 1
    return TextureImage(image.imageFilename, image.width, image.height, image.channels,image,false)
end

# ByteBuffer getBytePixelData() {
#     checkState(!unloaded);
#     checkState(0==bytePixelData.position(), "bytePixelData.position()!=0");
#     checkState(width*height* TextureImagesIO.BANDS==bytePixelData.remaining(),
#             "bytePixelData.remaining()==%d", bytePixelData.remaining());
#     return bytePixelData;
# }

function close(textureImage::TextureImage)
    checkState(!textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded")
    freedBytes = sizeof(textureImage.bytePixelData)
    # setting to nothing and waiting for the garbage collector should prevent a memory leak
    # may not be necessary
    textureImage.bytePixelData = nothing
    metrics.ramImageBytesCounter-= freedBytes
    metrics.ramTexturesCounter -= 1
    textureImage.unloaded = true
end

function getPixel(textureImage::TextureImage, coordinate::TextureCoordinate)::ColorSample
    checkState(!textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded")
    x = Int64(coordinate.x * (textureImage.width - 1))
    y = Int64(coordinate.y * (textureImage.height - 1))
    checkState(x >= 0 && x < textureImage.width, "Pixel value $x out of bounds in x")
    checkState(y >= 0 && y < textureImage.height, "Pixel value $y out of bounds in y")
    # betamax code: int offset = TextureImagesIO.BANDS * (width * y + x);
    # I think that for RGBA, 4 is what we want, so for now at least:
    offset = BANDS() * textureImage.width * y + x
    colorSample = ColorSample(
        get(textureImage.bytePixelData, (offset + 1) * sizeof(Cvoid)),
        get(textureImage.bytePixelData, (offset + 2) * sizeof(Cvoid)),
        get(textureImage.bytePixelData, (offset + 3) * sizeof(Cvoid)),
        get(textureImage.bytePixelData, (offset + 4) * sizeof(Cvoid))
    )
    @info "Pixel at $x✖$y is $colorSample (from $(textureImage.filename))"
    return colorSample
end

function uploadGl(textureImage::TextureImage, boundTarget::Int)
    checkState(!textureImage.unloaded, "TextureImage $(textureImage.filename) already unloaded")
    @time glTexImage2D(boundTarget, GL_RGBA8, textureImage.width, textureImage.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureImage.bytePixelData)

getByteCount(textureImage::TextureImage) = sizeof(textureImage.bytePixelData)

end
