using SparseArrays, TranscodingStreams, FileIO, CodecLz4
import Images.channelview, Base.getindex, Base.vec
include("/home/gil/.atom/doomfishjl/opengl/coordinates.jl")
include("/home/gil/.atom/doomfishjl/doomfishtool.jl")
include("TextureName2.jl")

testImageFilename = "/home/gil/Firefox_wallpaper.png"

abstract type JlImage end

struct MatrixImage <: JlImage
    imageFilename::String
    width::Int
    height::Int
    channels::Int
    matrix
end
function MatrixImage(imageFilename::String) :: MatrixImage
    img = channelview(load(imageFilename))
    channels = size(img)[1]
    height = size(img)[2]
    width = size(img)[3]
    matrix = convert.(Float32,reshape( img,(channels,:) ) )#
    return MatrixImage(imageFilename, width, height, channels, matrix)
end

struct SparseImage <: JlImage
    imageFilename::String
    width::Int
    height::Int
    channels::Int
    matrix::SparseMatrixCSC
end
function SparseImage(sourceImage::MatrixImage)
    matrix = sparse(sourceImage.matrix)
    return SparseImage(sourceImage.imageFilename, sourceImage.width, sourceImage.height, sourceImage.channels, matrix)
end
function SparseImage(imageFilename::String) :: SparseImage
    return SparseImage(MatrixImage(imageFilename))
end

# the indexing system for SparseImages and MatrixImages is based on TextureCoordinates, i.e. origin is bottom left, x̂ points right, ŷ points
# the image matrices are 2D, w/ dimensions of (channels, width*height). each column represents one pixel
# columns are placed in order by y value first, so the first (height) columns represent coordinates (x=1,y=1) to (x=1,y=height), in raster coordinates
# the next (height) columns represent (x=2,y=1) to (x=2, y=height), etc, for a total of width*height columns
# in TextureCoordinates, the y values are flipped, so the first (height) columns represent (x=1,y=height) to (x=1,y=1),
# the next (height) columns represent (x=2,y=height) to (x=2,y=1), etc.
# the algebraic dogfuck below accounts for this.
function getindex(image::MatrixImage, x::Int, y::Int)
        return image.matrix[:, (x-1)*image.height + (image.height-y)+1 ] # <-- the expression in that index call is redundant, I know, but
end                                                                    #     I find the algebra easier to think about this way.
getindex(image::MatrixImage, x::Colon, y::Int) = [image[i,y] for i in 1:image.width]
getindex(image::MatrixImage, x::Int, y::Colon) = [image[x,j] for j in 1:image.height]

function getindex(image::SparseImage, x::Int, y::Int)
    index = (x-1)*image.height + (image.height-y)+1
    return [image.sparseMatrix[CartesianIndex(j,index)] for j in 1:image.channels]
end

vec(image::MatrixImage) = vec(image.matrix)
vec(sparseImage::SparseImage) = vec(image.sparseMatrix)


# move below to separate ImageIO file


function cacheImage(image::I) where I <: JlImage
    cachedOutputName = cachedFilename(image.imageFilename)
    buffer = IOBuffer()
    for value in image.matrix
        write(buffer,value)
    end
    compressedData = transcode(LZ4HCCompressor,buffer.data)
    stream = open(cachedOutputName, create=true, write=true)
    write(stream, compressedData)
    close(stream)
    close(buffer)
end

function loadCachedImage(imageFilename::String)
    stream = open(cachedFilename(imageFilename), read=true)
    compressedData = read(stream)
    imageData = transcode(LZ4SafeDecompressor, compressedData)
    close(stream)
    return imageData
end
