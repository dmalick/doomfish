using OrderedCollections
include("/home/gil/doomfish/doomfishjl/metrics/StatsName.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("assetfilepatterns.jl")

# FIXME: this is terrible. I mean goddamn
# maybe write a macro to generate these dicts? or a per-type struct?

@enum AssetType begin
    TEXTURE_IMAGE
    MESH
    SOUND
    SPRITE
    MODEL
end


ASSET_TYPES = OrderedDict{ Regex, AssetType }(
    IMAGE_PATTERN => TEXTURE_IMAGE,
    MESH_PATTERN => MESH,
    SOUND_PATTERN => SOUND,
    CACHED_TEXTURE_IMAGE_PATTERN => TEXTURE_IMAGE,
    CACHED_MESH_PATTERN => MESH,
    CACHED_SOUND_PATTERN => SOUND
)


function getAssetType(filename::String)
    checkArgument( occursin( ASSET_PATTERN, filename ), "filename $filename is not a valid asset type" )

    assetType = filter( extension-> occursin( extension.first, filename ), ASSET_TYPES )
    checkState( length(assetType) == 1, "filename $filename matches more than one concrete asset type, (IMAGE_PATTERN, SOUND_PATTERN, ETC)" )

    return assetType[1].second
end


CACHE_KEYS = OrderedDict( MESH_PATTERN => meshCacheKey, IMAGE_PATTERN => textureCacheKey, SOUND_PATTERN => soundCacheKey )


function cacheKeyFromFilename(filename::String)
    checkArgument( occursin( ASSET_PATTERN, filename ), "filename $filename is not a valid asset type" )

    cacheKey = filter( assetPattern-> occursin( assetPattern.first, filename ), CACHE_KEYS )
    checkState( length(cacheKey) == 1, "filename $filename matches more than one concrete asset type (IMAGE_PATTERN, SOUND_PATTERN, ETC)" )

    return cacheKey[1].second
end
