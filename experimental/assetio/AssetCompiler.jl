using Logging

include("AssetIO.jl")
include("assetlists/AssetListsPackage.jl")


function compileAssets()
    @info "Compiling asset lists"
    assetListsPackage = compileAssetListsPackage()
    writeToFile( assetListsPackage )

    @info "Collecting asset filenames"

    totalAssetPaths = length( getAssetPaths() )

    neededTextures = needCompiling( IMAGE_PATTERN )
    neededMeshes = needCompiling( MESH_PATTERN )
    neededSounds = needCompiling( SOUND_PATTERN )

    totalAssetsNeeded = sum( length, [ neededTextures, neededMeshes, neededSounds ] )

    @info "Found $totalAssetPaths assets on disk ($totalAssetsNeeded need compiling)"

    compileAssets( neededTextures, TextureName )
    compileAssets( neededMeshes, MeshName )
    compileAssets( neededSounds, SoundName )
end


function compileAssets(compilePaths::Vector{String}, assetNameType::Type{N}) where N <: AssetName
    if compilePaths |> isempty
        @info "No assets found for asset type $assetNameType"
        return
    end
    ct = 1
    startTime = time_ns()
    for path in compilePaths
        now = time_ns()
        # I sorta suspect the eta math is funky. Just copied it from betamax and converted to nanoseconds
        eta = length( compilePaths ) * (now - startTime) / ct - now + startTime
        @info "Compiling $assetNameType $ct of $(length(compilePaths)), ($( 100 * ct/length( compilePaths ))%, eta $(eta/10^9))"
        ct += 1
        asset = assetFromFile( assetNameType(path) )
        saveToCache( true, asset )
        close( asset )
    end
    @info "Successfully recompiled $(length(compilePaths))"
end


function isUpToDate(inputFile::String) :: Bool
    cacheKey = cacheKeyFromFilename( inputFile )
    outputFile = cachedFilename( cacheKey, inputFile )
    if !isfile(outputFile)
        return false
    end
    @info "Input $inputFile last modified $(stat(inputFile).mtime)"
    @info "Output $outputFile last modified $(stat(outputFile).mtime)"
    return stat(inputFile).mtime < stat(outputFile).mtime
end


function needCompiling(pattern)
    return vcat( needCompiling(spritePathBase, pattern), needCompiling(modelPathBase, pattern) )
end

function needCompiling(pathBase::String, pattern::Regex)
    return [ assetPath for assetPath in getAssetPaths( pathBase, pattern ) if !isUpToDate( assetPath ) ]
end


function getAssetPaths()

    # FIXME fuck this
    # FIXME, also, it may be the case that both a sprite and a model share an asset.
    # In this case, ideally we'd find a way to only cache it once and let them both use it.
    # Easier said than done.

    spriteTexturePaths = getAssetPaths( spritePathBase, IMAGE_PATTERN )
    spriteSoundPaths = getAssetPaths( spritePathBase, SOUND_PATTERN )

    modelTexturePaths = getAssetPaths( modelPathBase, IMAGE_PATTERN )
    modelSoundPaths = getAssetPaths( modelPathBase, SOUND_PATTERN )
    meshPaths = getAssetPaths( modelPathBase, MESH_PATTERN )

    return vcat( spriteTexturePaths, spriteSoundPaths, modelTexturePaths, modelSoundPaths, meshPaths )

end


function getAssetPaths(pathBase::String, pattern::Regex)
    if readdir(pathBase) |> isempty
        return Vector{String}()
    end
    return [ ( pathBase * templatePath * "/" * filename ) for templatePath in readdir(pathBase)
             for filename in readdir( pathBase * templatePath ) if occursin( pattern, filename ) ]
end
