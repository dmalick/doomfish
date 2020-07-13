import Base.convert, Base.isless
include("globalvars.jl")


abstract type AssetName end


# raw (upstream) AssetName definitions
# raw asset names for assets that can be cached carry around
# their particular cache keys for convenience.

struct TextureName <: AssetName # applies to both Textures and TextureImages
    filename::String
    cacheKey::String
    TextureName(filename) = new( filename, textureCacheKey )
end

struct MeshName <: AssetName # applies to both Meshes and RawMeshes
    filename::String
    cacheKey::String
    MeshName(filename) = new( filename, meshCacheKey )
end

struct SoundName <: AssetName # applies to both Sounds and SoundSamples
    filename::String
    cacheKey::String
    SoundFileName(filename) = new( filename, soundCacheKey )
end


# in-game (midstream) AssetName definitions

struct SpriteName <: AssetName
    name::String
end

struct ModelName <: AssetName
    name::String
end



# define converts for feeding filenames directly into constructors as strings

function convert(::Type{String}, assetName::A) where A <: AssetName
    nameField = fieldnames(A)[1]
    return assetName.:($nameField)
end

function isless(a::A, b::A) where A <: AssetName
    nameField = fieldnames(A)[1]
    return a.:($nameField) < b.:($nameField)
end



# define string prefix macros allowing for example sprite"name" as shorthand for
# SpriteName( "name" ), using special `@ _str` builtin macros,
# i.e. @r_str( string ) to define r"string" = Regex( "string" )

assetnames = filter( asset-> occursin( r".+Name", asset ), string.( subtypes(AssetName) ) )

# format strings "SampleName" to "sample_str" as required for @_str macro definitions
macronames = split.( assetnames, "Name" )
macronames = [ name[1] for name in macronames ]
macronames = lowercase.( macronames )
macronames = [ name*"_str" for name in macronames ]

macronames = Symbol.(macronames)
names = Symbol.(assetnames)

macrodefs = [ quote
                macro $(macronames[i])(name)
                    return $(names[i])( name ) end end
             for i in 1:length(macronames)]
eval.(macrodefs)
