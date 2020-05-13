using Serialization
include("SpriteTemplateManifest.jl")


struct ManifestsPackage
    manifestsDict::Dict{String, SpriteTemplateManifest}
end
function compileManifestsPackage()
    return ManifestsPackage(preloadEverything())
end


function writeToFile(manifestsPackage::ManifestsPackage)
    serialize(manifestsPackageFilename, manifestsPackage)
    # this may not be necessary
    return manifestsPackageFilename
end


function readManifestsPackageFromFile()
    return deserialize(manifestsPackageFilename)
end
