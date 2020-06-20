using Serialization
include("SpriteAssetList.jl")
include("ModelAssetList.jl")

struct AssetListsPackage
    assetListDict::Dict{String, AssetList}
end


function compileAssetListsPackage()
    assetLists = merge( preloadSpriteAssetLists(), preloadModelAssetLists() )
    return AssetListsPackage( assetLists )
end


function writeToFile(assetListsPackage::AssetListsPackage)
    serialize( assetListsPackageFilename, assetListsPackage )
    # this may not be necessary
    return assetListsPackage
end


function readAssetListsPackageFromFile()
    return deserialize( assetListsPackageFilename )
end
