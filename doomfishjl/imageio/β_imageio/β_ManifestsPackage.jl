using Serialization
include("SpriteTemplateManifest.jl")


manifestsPackage = Dict{String, SpriteTemplateManifest}()

function compileManifestsPackage()
    return preloadManifests()
end


function writeManifestsPackageToFile()
    serialize(manifestsPackageFilename, manifestsPackage)
    # this may not be necessary
    return manifestsPackageFilename
end


function readManifestsPackageFromFile()
    return deserialize(manifestsPackageFilename)
end
