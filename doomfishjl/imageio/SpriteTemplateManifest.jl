using Logging
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("/home/gil/doomfish/doomfishjl/assetnames.jl")


#=  betamax:
/** The indirection between SpriteTemplateManifest/SpriteTemplate is here so we can find out all the constituent
 * files early before doing the expensive work of loading the textures, so we can use the data for other purposes,
 * like resolving named moments
 *
 * Also of course isolate all the noise of dealing with file system paths */
=#

# TODO: we want to add significant sound functionality on top of the original betamax.
# this will probably include support for multiple filetypes in addition to moment functionality.
# WARNING I'm not entirely sure how julia regexes differ from java regexes. Should be simpler though.
IMG_PATTERN = r".*\.(tif|png|jpeg|jpg|bmp)"
IMG_OR_SOUND_PATTERN = r".*\.(ogg|tif|png|jpeg|jpg|bmp)"
SOUND_PATTERN = r".*\.ogg"
MOMENT_PATTERN = r".*\[.+\].*\.(tif|png|jpeg|jpg|bmp)" # TODO: eventually add moment functionality for sounds
MOMENT_TAG_PATTERN = r".*\[(.+)\]"


struct SpriteTemplateManifest

    templateName::String
    textureNames::Vector{TextureName}
    soundNames::Vector{SoundName}

    function SpriteTemplateManifest(templateName, textureNames, soundNames)
        # TODO: when additional sound functionality is added we'll remove this restriction
        checkArgument( length(soundNames) <= 1, "Too many OGG files for sprite template $templateName" )
        checkArgument(0 != length(textureNames), "No sprite frame files found for $templateName")
        if !(textureNames |> issorted)
            sort!(textureNames)
        end
        if !(soundNames |> issorted)
            sort!(soundNames)
        end
        return new(templateName, textureNames, soundNames)
    end
end


# not used anywhere yet
function preloadEverythingCompiled() :: Dict{String, SpriteTemplateManifest}
    # betamax: return ManifestsPackage.readFromFile().getManifestsMap();
end



# it's possible this whole DraftManifest business is totally unnecessary w/
# the way we've written the preloadEverything() function
mutable struct DraftManifest
    textureNames::Vector{TextureName}
    soundNames::Vector{SoundName}
end
function addAsset!(draftManifest::DraftManifest, assetPath::String)
    splitPath = split(assetPath,".")
    extension = splitPath[length(splitPath)] |> lowercase
    if extension in (".tif", ".png", ".jpg", ".jpeg", ".bmp")
        push!(draftManifest.textureNames, TextureName(assetPath))
    elseif extension in (".ogg") # TODO: when we do add sound functionality, expand this list as needed
        push!(draftManifest, SoundName(assetPath))
    else
        throw(ArgumentError(extension, "unrecognized asset file extension $extension in $assetPath"))
    end
end
# end DraftManifest shit


function preloadEverything() :: Dict{String, SpriteTemplateManifest}
    templateNames = readdir(spritePathBase)
    @info "Preloading $(length(templateNames)) SpriteTemplateManifests"
    return Dict(templateName => loadSpriteTemplateManifest(templateName) for templateName in templateNames)
end


# retooled, taking advantage of the split function.
# for asset names ~20 chars and up, this version matches betamax performance in time and outperforms in memory (not that it matters much)
function findTemplateName(assetPath::String)
    checkArgument(startswith(assetPath, spritePathBase) && !endswith(assetPath, "/"), "bad asset path $assetPath")
    assetPathSplit =  split(assetPath, "/")
    return assetPathSplit[length(assetPathSplit) - 1]
end


# this is entirely different from the betamax code. the comps are much cleaner than the java reflections and not even slow.
# (of course we couldn't write it the way it's written in the java even if we wanted to.)
# this could also have been written with the filter function which might possibly be faster for large data sets
# however, for small test data sets it performs the same, and it requires a convert method which completely
# negates the type safety of the betamax TextureName and SoundName wrappers. As it is there are convert methods for
# going from TextureName/SoundName to String, but not the other way around.
function loadSpriteTemplateManifest(templateName::String)
    templatePathContents = readdir( spritePathBase * templateName)
    spriteFilenames = [TextureName(filename) for filename in templatePathContents if occursin(IMG_PATTERN, filename)]
    soundFilenames = [SoundName(filename) for filename in templatePathContents if occursin(SOUND_PATTERN, filename)]
    return SpriteTemplateManifest(templateName, spriteFilenames, soundFilenames)
end


function getMomentNamedTextures(manifest::SpriteTemplateManifest)
    return momentNamedTextures = [textureName for textureName in manifest.textureNames if occursin(MOMENT_PATTERN, textureName.filename)]
end


function getMomentName(textureName::TextureName)
    if nothing != match( MOMENT_TAG_PATTERN, textureName.filename )
        return match( MOMENT_TAG_PATTERN, textureName.filename ).captures[1]
    end
    throw(ArgumentError("TextureName $textureName is not a moment named texture"))
end


# WARNING not entirely sure if this does what it should yet. we'll have to see it used in context first.
# the betamax code is java regex boilerplate packed inside a map function. I've translated it to the best
# of my ability but by no means literally. it's possible I've misunderstood what the java actually does.
function getMomentNames(manifest::SpriteTemplateManifest)
    momentNamedTextures = getMomentNamedTextures(manifest)
    if !( momentNamedTextures |> isempty )
        return momentNames = [match( MOMENT_TAG_PATTERN, textureName.filename ).captures[1] for textureName in momentNamedTextures]
    else
        return []
    end
end


# WARNING not entirely sure if this does what it should yet. we'll have to see it used in context first.
# this is an educated guess at what this function should do. it's possible I've misunderstood what the java actually does.
# what this essentially does is return what index the named moment occurs at within the
# set of ALL textures.
function getMomentIDByName(manifest::SpriteTemplateManifest, desiredMomentName::String)
    momentID = 1
    momentNamedTextures = getMomentNamedTextures(manifest)
    for textureName in manifest.textureNames
        if textureName in momentNamedTextures
            if getMomentName(textureName) == desiredMomentName
                return momentID
            end
        end
    momentID += 1
    end
    throw(ArgumentError("No moment named '$(desiredMomentName)' in $(manifest.templateName)"))
end


# WARNING not entirely sure if this does what it should yet. we'll have to see it used in context first.
# this is more or less copped directly from the betamax code, whereas the getMomentNames() function
# is heavily translated. it's possible I've misunderstood what the java actually does.
# what this essentially does is return what index the named moment occurs at within the
# set of MOMENT-NAMED textures.
function getCountNumberOfNamedMoment(manifest::SpriteTemplateManifest, desiredMomentName::String)
    momentID = 1
    for momentName in getMomentNames(manifest)
        if momentName == desiredMomentName
            return momentID
        end
    momentID += 1
    end
    throw(ArgumentError("No moment named '$desiredMomentName' in $(manifest.templateName)"))
end
