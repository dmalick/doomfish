using Logging

includepath("doomfishjl/globalvars.jl")
includepath("doomfishjl/doomfishtool.jl")
includepath("doomfishjl/assetnames.jl")
include("TextureImagesIO.jl")
include("ManifestsPackage.jl")


function compileTextures()
    @info "Compiling manifests"
    manifestsPackage = compileManifestsPackage()
    writeToFile(manifestsPackage)

    @info "Collecting texture filenames"

    texturePaths = [(spritePathBase*templatePath*"/"*filename) for templatePath in readdir( spritePathBase )
                    for filename in readdir( spritePathBase*templatePath ) if occursin(IMG_OR_SOUND_PATTERN, filename)]
    needCompiling = [texturePath for texturePath in texturePaths if !isUpToDate(texturePath)]

    @info "Found $(length(texturePaths)) textures on disk ($(length(needCompiling)))"

    jj = 1
    startTime = time_ns()
    for texturePath in needCompiling
        now = time_ns()
        eta = length( needCompiling ) * (now - startTime) / jj - now + startTime
        @info "Compiling texture $jj of $(length(needCompiling)), ($( 100 * jj/length( needCompiling ))%, eta $(eta/1000))"
        jj+=1
        #textureImage = textureImageFromFile(texturePath)
        textureImage = textureImageFromFile(texturePath)
        saveToCache(true, textureImage)
        close(textureImage)
    end
    @info "Successfully recompiled $(length(needCompiling))"
end


function isUpToDate(inputFile::String) :: Bool
    outputFile = cachedFilename( TextureName(inputFile) )
    if !isfile(outputFile)
        return false
    end
    @info "Input $inputFile last modified $(stat(inputFile).mtime)"
    @info "Output $outputFile last modified $(stat(outputFile).mtime)"
    return stat(inputFile).mtime < stat(outputFile).mtime
end
