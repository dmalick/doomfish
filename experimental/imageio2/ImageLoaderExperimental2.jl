import FileIO.load, Images.channelview
include("/home/gil/.atom/doomfishjl/imageio/colorsample.jl")
include("/home/gil/.atom/doomfishjl/opengl/coordinates.jl")

# for testing purposes
testImageFilename = "/home/gil/Firefox_wallpaper.png"

# WARNING: everything below is in opengl screen coordinates.
# i.e. the origin (0,0) is dead middle of the screen, edges of the screen are ⨦1.0
# colors are RGB / RGBA, where 0 is black and 1.0 is saturated.
# for α values, 0 is transparent, 1.0 is opaque.
# the integerValueMatrix function will return integers, just as a sanity check.

# this is probably sloppy, but returns a vector that can be passed directly into a VAO

function getVertexArray(img) :: Array{Float32,1}
    return convert(Array{Float32,1}, imageAsVector(img))
end
getVertexArray(imageFilename::String) = getVertexArray(load(imageFilename))

function imageAsVector(img) :: Array{Float64,1}
    return vec( transpose(imageAsMatrix(img)) )
end
imageAsVector(imageFilename::String) = imageAsVector(load(imageFilename))

# there's probably a better way to do this
function imageAsMatrix(img) :: Array{Float64,2}
    colorArray = channelview(img)
    channels = size(colorArray)[1]
    height = size(colorArray)[2]
    width = size(colorArray)[3]
    colorVec = vec(colorArray)
    colorArray = reshape(colorVec, (channels, size(colorVec)[1]÷channels))
    colorArray = transpose(colorArray)
    yVec = vec( [-(2i/height)+1 for i in 1:height, j in 1:width] )
    xVec = vec( [(2j/width)-1 for i in 1:height, j in 1:width] )
    posVec = hcat(xVec,yVec)
    colorArray = hcat(posVec,colorArray)

    return colorArray
end
imageAsMatrix(imageFilename::String) = imageAsMatrix(load(imageFilename))

# WARNING: the integerValueMatrix function is meant only as a sanity check.
# its results are not compatible w/ opengl
function integerValueMatrix(img) :: Array{Int,2}
    colorArray = channelview(img)
    channels = size(colorArray)[1]
    height = size(colorArray)[2]
    width = size(colorArray)[3]
    colorVec = vec(colorArray)
    colorArray = reshape(colorVec, (channels, size(colorVec)[1]÷channels))
    colorArray = transpose(colorArray)
    colorArray = convert(Array{Int,2}, colorArray.*255)
    yVec = vec( [-i for i in 1:height, j in 1:width] )
    xVec = vec( [j for i in 1:height, j in 1:width] )
    posVec = hcat(xVec,yVec)
    colorArray = hcat(posVec,colorArray)

    return colorArray
end
integerValueMatrix(imageFilename::String) = integerValueMatrix(load(imageFilename))


# this is terrible. sorry
function matrixToColorSamples(imageMatrix) :: Array{ColorSample,1}
    channels = size(imageMatrix)[2] - 2
    type = typeof(imageMatrix[1,3])
    if type <: AbstractFloat && type != Float32
        return [ColorSample(Tuple(convert(Float32,imageMatrix[j,:][i+2]) for i in 1:channels)) for j in 1:size(imageMatrix)[1]]
    end
    return [ColorSample(Tuple(imageMatrix[j,:][i+2] for i in 1:channels)) for j in 1:size(imageMatrix)[1]]
end

function matrixToFramebufferCoordinates(imageMatrix) :: Array{FramebufferCoordinate,1}
    return [FramebufferCoordinate(imageMatrix[i,1], imageMatrix[i,2]) for i in 1:size(imageMatrix)[1]]
end

function matrixToTextureCoordinates(imageMatrix) :: Array{TextureCoordinate,1}
    return [toTextureCoordinate(FramebufferCoordinate(imageMatrix[i,1], imageMatrix[i,2])) for i in 1:size(imageMatrix)[1]]
end

# typesafe wrapper for image matrices
function arraysToCoordColorDict(coordinateArray::Array{T,1}, colorSampleArray::Array{ColorSample,1}) :: Dict{T,ColorSample} where T <: GlCoordinate
    checkState(size(coordinateArray)[1] == size(colorSampleArray)[1], "could not map $coordinateArray to $colorSampleArray: dimensions do not match")
    return Dict(coordinateArray[i] => colorSampleArray[i] for i in 1:size(coordinateArray)[1])
end

function matrixToCoordColorDict(coordinateType::Type{C}, imageMatrix::Array{T,2}) :: Dict{C,ColorSample} where T <: AbstractFloat where C <: GlCoordinate
    posArray = coordinateType == FramebufferCoordinate ? matrixToFramebufferCoordinates(imageMatrix) : matrixToTextureCoordinates(imageMatrix)
    colorArray = matrixToColorSamples(imageMatrix)
    return arraysToCoordColorDict(posArray,colorArray)
end

function imageToCoordColorDict(coordinateType::Type{C}, img::Array{ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8,8}},2}) :: Dict{C,ColorSample} where C <: GlCoordinate
    return matrixToCoordColorDict(coordinateType, imageAsMatrix(img))
end
imageToCoordColorDict(coordinateType, imageFilename::String) = imageToCoordColorDict(coordinateType, load(imageFilename))

function getVertexArray(coordColorDict::Dict{C,ColorSample}) :: Array{Float32,1} where C <: GlCoordinate
