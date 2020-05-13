using SparseArrays
import FileIO.load, Images.channelview, Base.zero, Base.getindex
# include("/home/gil/.atom/doomfishjl/opengl/coordinates.jl")
# include("/home/gil/.atom/doomfishjl/imageio/colorsample2.jl")

testImageFilename = "/home/gil/Firefox_wallpaper.png"

# these zero definitions are needed to be able to store NTuple values in SparseMatrixCSC's
zero(::NTuple{4,Float32}) = (0f0,0f0,0f0,0f0)
zero(::NTuple{3,Float32}) = (0f0,0f0,0f0)

struct SparseImage
    imageFilename::String
    cached::Bool
    cachedFilename::Union{String, Nothing}
    width::Int
    height::Int
    channels::Int
    matrixRepresentation::Union{SparseMatrixCSC{NTuple{4,Float32}, Int}, SparseMatrixCSC{NTuple{3,Float32}, Int}}
end
function SparseImage(imageFilename::String)
    img = channelview(load(imageFilename))
    channels = size(img)[1]
    height = size(img)[2]
    width = size(img)[3]
    matrixRepresentation = sparse(Matrix([Tuple(convert(Array{Float32},img[:,j,i])) for i in 1:width, j in 1:height]))
    return SparseImage(imageFilename, false, nothing, width, height, channels, matrixRepresentation)
end

function getindex(image::SparseImage, x::Int, y::Int)
    return image.matrixRepresentation[CartesianIndex(x,y)]
end

function toVertex(image::SparseImage, x::Int, y::Int)
    channels = image[x,y]
    return [(2x/image.width)-1,-(2y/image.height)+1,channels...]
end

function toVertexArray(image::SparseImage)
     return vcat( [toVertex(image,i,j) for i in 1:image.width for j in 1:image.height]...)
end

function toTexturePixel(image::SparseImage, x::Int, y::Int)
    channels = image[x,y]
    return [x/image.width, 1-y/image.height, channels...]
end
