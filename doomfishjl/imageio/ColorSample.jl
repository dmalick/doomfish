using Logging
import Base.*, Base.convert


struct ColorSample{T<:Union{Int,Float32}}
    r::T
    g::T
    b::T
    a::T
end

function convert(::Type{ColorSample{Float32}}, colorSample::ColorSample{Int}) :: ColorSample{Float32}
    return ColorSample( Tuple( value/255 |> Float32 for value in (colorSample.r,colorSample.g,colorSample.b,colorSample.a) ) )
end
function convert(::Type{ColorSample{Int}}, colorSample::ColorSample{Float32}) :: ColorSample{Int}
    return ColorSample( Tuple( round(value*255) |> Int for value in (colorSample.r,colorSample.g,colorSample.b,colorSample.a) ) )
end


ColorSample(r,g,b) = typeof(r) == Int ? ColorSample(r,g,b, 255) : ColorSample(r,g,b,1.0f0)
ColorSample(color::NTuple{4}) = ColorSample(color[1],color[2],color[3],color[4])
ColorSample(color::NTuple{3}) = ColorSample(color[1],color[2],color[3])


checkColor(colorValue::Int) = checkState(colorValue <=255 && colorValue>= 0, "colorValue $colorValue out of bounds")
checkColor(colorValue::Float32) = checkState(colorValue <=1.0f0 && colorValue>= 0.0f0, "colorValue $colorValue out of bounds")


function checkIfValid(colorSample::ColorSample) :: Bool
    checkState(typeof(colorSample.r)==typeof(colorSample.g)==typeof(colorSample.b)==typeof(colorSample.a),
               "color values in $colorSample are not of same type")
    checkColor(colorSample.r)
    checkColor(colorSample.g)
    checkColor(colorSample.b)
    checkColor(colorSample.a)
    return true
end


# is it transparent enough for the human eye to notice?
function isTransparentEnough(colorsample::ColorSample)
    return typeof(colorsample.a) == Float32 ? colorsample.a < 200/255f0 : colorsample.a < 200
end


function *(scalar::Union{Int, AbstractFloat}, color::ColorSample)
    colorSample = ColorSample(scalar .* (color.r,color.g,color.b,color.a))
    checkIfValid(colorSample)
    return colorSample
end
*(color::ColorSample, scalar::Union{Int, AbstractFloat}) = scalar * color


function toFloat(colorSample::ColorSample)
    if typeof( colorSample ) == ColorSample{Float32}
        @warn "Attempted to convert ColorSample to its existing type (Float32). ColorSample not converted"
        return colorSample
    end
    return convert(ColorSample{Float32}, colorSample)
end


ColorSampleToFloat(r,g,b,a) = toFloat(ColorSample(r,g,b,a))
ColorSampleToFloat(color::NTuple{4}) = toFloat(ColorSample(color))
