import Base.convert, Base.isless
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("AssetType.jl")


abstract type AssetName end


struct TextureName <: AssetName
    filename::String
    type::AssetType
    headerSize::Int
    cacheKey::String
    loadingStatsName::StatsName
    cached::Bool
    TextureName(filename; cached=false) = new( filename, TEXTURE_IMAGE, 3, textureCacheKey, TEXTURE_IMAGE_LOADING_STATS, cached )
end

struct MeshName <: AssetName
    filename::String
    type::AssetType
    headerSize::Int
    cacheKey::String
    loadingStatsName::StatsName
    cached::Bool
    MeshName(filename; cached=false) = new( filename, MESH, 1, meshCacheKey, MESH_LOADING_STATS, cached )
end

struct SoundName <: AssetName
    filename::String
    type::AssetType
    headerSize::Int
    cacheKey::String
    loadingStatsName::StatsName
    cached::Bool
    SoundName(filename; cached=false) = new( filename, SOUND, 1, soundCacheKey, SOUND_LOADING_STATS, cached )
end


struct SpriteName <: AssetName
    name::String
    type::AssetType
    SpriteName(name) = new( name, SPRITE )
end

struct ModelName <: AssetName
    name::String
    type::AssetType
    ModelName(name) = new( name, MODEL )
end


function convert(::Type{String}, assetName::A) where A <: AssetName
    nameField = fieldnames(A)[1]
    return assetName.:($nameField)
end

function convert(::Type{AssetType}, assetName::AssetName)
    return assetName.type
end

function isless(a::A, b::A) where A <: AssetName
    nameField = fieldnames(A)[1]
    return a.:($nameField) < b.:($nameField)
end


function convert(::Type{String}, nameType::Type{A}) where A <: AssetName
    if hasfield( nameType, :(type) ) return lowercase( string(nameType.type) )
    else return string(nameType) end
end
