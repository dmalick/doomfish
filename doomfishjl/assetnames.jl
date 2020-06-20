import Base.convert, Base.isless
include("globalvars.jl")


abstract type AssetName end


struct TextureName <: AssetName
    filename::String
    cacheKey::String
    TextureName(filename) = new( filename, textureCacheKey )
end

struct MeshName <: AssetName
    filename::String
    cacheKey::String
    MeshName(filename) = new( filename, meshCacheKey )
end

struct SoundName <: AssetName
    filename::String
    cacheKey::String
    SoundName(filename) = new( filename, soundCacheKey )
end


struct SpriteName <: AssetName
    name::String
end

struct ModelName <: AssetName
    name::String
end


function convert(::Type{String}, assetName::A) where A <: AssetName
    nameField = fieldnames(A)[1]
    return assetName.:($nameField)
end

function isless(a::A, b::A) where A <: AssetName
    nameField = fieldnames(A)[1]
    return a.:($nameField) < b.:($nameField)
end
