import Base.convert, Base.isless


abstract type AssetName end


struct TextureName <: AssetName
    filename::String
end

struct MeshName <: AssetName
    filename::String

struct SoundName <: AssetName
    filename::String
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
