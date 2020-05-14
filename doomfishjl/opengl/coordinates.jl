import Base.+, Base.-, Base.convert
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")

# TextureCoordinates are bounded 0 to 1.0 or 0 to width, FramebufferCoordinates -1.0 to 1.0
# Functions for converting between the two and addition/subtraction

abstract type GlCoordinate end

struct FramebufferCoordinate <: GlCoordinate
    x::Float32
    y::Float32
    function FramebufferCoordinate(x,y)
        testCoord = new(x,y)
        checkState(isValidCoordinate(testCoord), "could not create $testCoord: coordinates ($x, $y) are out of bounds for type FramebufferCoordinate.
        FramebufferCoordinates are bound between -1.0 and +1.0")
        return testCoord
    end
end
FramebufferCoordinate(pos::Tuple{2}) = FramebufferCoordinate(pos...)

struct TextureCoordinate <: GlCoordinate
    x::Float32
    y::Float32
    function TextureCoordinate(x,y)
        testCoord = new(x,y)
        checkState(isValidCoordinate(testCoord), "could not create $testCoord: coordinates ($x, $y) are out of bounds for type TextureCoordinate.
        TextureCoordinates are bound between 0 and 1.0")
        return testCoord
    end
end

TextureCoordinate(pos::Tuple{2}) = TextureCoordinate(pos...)

function TextureCoordinate(pos::CartesianIndex, width::Int, height::Int)
    x = Float32( (pos[1]) / width )
    y = Float32( (pos[2]) / height )
    return TextureCoordinate(x,y)
end



function isValidCoordinate(coordType::Type{T}, x::Number, y::Number)::Bool where T <: GlCoordinate
    return ( (coordType==FramebufferCoordinate && x >= -1.0 && x <= 1.0 && y >= -1.0 && y <= 1.0)
           ||(coordType==TextureCoordinate && x >= 0.0 && x <= 1.0 && y >=0.0 && y <= 1.0) )
end
isValidCoordinate(coord::FramebufferCoordinate) = (coord.x >= -1.0 && coord.x <= 1.0 && coord.y >= -1.0 && coord.y <= 1.0)
isValidCoordinate(coord::TextureCoordinate) = (coord.x >= 0.0 && coord.x <= 1.0 && coord.y >=0.0 && coord.y <= 1.0)


# conversions
# note that these conversions preserve absolute position between coordinate systems.
# i.e., TextureCoordinate(0.0 ,1.0) -> FramebufferCoordinate(-1.0, 1.0),
# FramebufferCoordinate(-0.5, 1) - > TextureCoordinate(0.25, 1.0), etc

function toFramebufferCoordinate(coord::TextureCoordinate) :: FramebufferCoordinate
    return FramebufferCoordinate(coord.x*2-1, coord.y*2-1)
end
convert(::Type{TextureCoordinate}, fbc::FramebufferCoordinate) = toTextureCoordinate(fbc)

function toTextureCoordinate(coord::FramebufferCoordinate) :: TextureCoordinate
    return TextureCoordinate((coord.x+1)/2, (coord.y+1)/2)
end
convert(::Type{FramebufferCoordinate}, txc::TextureCoordinate) = toFramebufferCoordinate(txc)


# addition/subtraction

function -(c1::T, c2::T) where T <: GlCoordinate
    #checkState(isValidCoordinate(T, c1.x-c2.x, c1.y-c2.y), "cannot subtract $c1 and $c2 : result out of bounds for type $T.")
    return T(c1.x-c2.x, c1.y-c2.y)
end

function +(c1::T, c2::T) where T <: GlCoordinate
    #checkState(isValidCoordinate(T, c1.x+c2.x, c1.y+c2.y), "cannot add $c1 and $c2 : result out of bounds for type $T.")
    return T(c1.x+c2.x, c1.y+c2.y)
end

# function toShortString(coord::TextureCoordinate)
#     Return ""
