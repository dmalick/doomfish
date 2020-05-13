import FileIO.load, Images.channelview

# for testing purposes
testImageFilename = "/home/gil/Firefox_wallpaper.png"

# WARNING: everything below is in opengl screen coordinates.
# i.e. the origin (0,0) is dead middle of the screen, edges of the screen are ⨦1.0
# colors are RGB / RGBA, where 0 is black and 1.0 is saturated.
# for α values, 0 is transparent, 1.0 is opaque.
# the integerValueMatrix function will return integers, just as a sanity check.

# this is probably sloppy, but returns a vector that can be passed directly into a VAO

function getVertexArray(img)
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
    yVec = vec( [i for i in 1:height, j in 1:width] )
    xVec = vec( [j for i in 1:height, j in 1:width] )
    posVec = hcat(xVec,yVec)
    colorArray = hcat(posVec,colorArray)

    return colorArray
end
integerValueMatrix(imageFilename::String) = integerValueMatrix(load(imageFilename))
