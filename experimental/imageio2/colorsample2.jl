using Logging
import Base.zero
include("/home/gil/.atom/doomfishjl/doomfishtool.jl")

struct ColorSample
    r::Float32
    g::Float32
    b::Float32
    α::Float32
    toTuple::NTuple{4,Float32}
    function ColorSample(r,g,b,α)
        checkState(r >= 0.0 && r <= 1.0, "could not create ColorSample($r,$b,$g,$α): r value $r out of bounds")
        checkState(g >= 0.0 && g <= 1.0, "could not create ColorSample($r,$b,$g,$α): g value $g out of bounds")
        checkState(b >= 0.0 && b <= 1.0, "could not create ColorSample($r,$b,$g,$α): b value $b out of bounds")
        checkState(α >= 0.0 && α <= 1.0, "could not create ColorSample($r,$b,$g,$α): α value $α out of bounds")
        return new(r,g,b,α,(r,g,b,α,))
    end
end
ColorSample(r,g,b) = ColorSample(r,g,b,1)
ColorSample(color::NTuple{4}) = ColorSample(color[1],color[2],color[3],color[4])
ColorSample(color::NTuple{3}) = ColorSample(color[1],color[2],color[3])

zero(ColorSample) = ColorSample(0,0,0,0)
