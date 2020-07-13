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

IMG_EXTENSIONS = "tif|png|jpeg|jpg|bmp"
MESH_EXTENSIONS = "obj|stl|ply|off|2DM"
SOUND_EXTENSIONS = "ogg"

# TODO: we want to add significant sound functionality on top of the original betamax.
# this will probably include support for multiple filetypes in addition to moment functionality.

const ASSET_PATTERN = Regex( ".+\\.($IMG_EXTENSIONS|$MESH_EXTENSIONS|$SOUND_EXTENSIONS)" )
const IMG_PATTERN = Regex( ".+\\.($IMG_EXTENSIONS)" )
const MESH_PATTERN = Regex( ".+\\.($MESH_EXTENSIONS)" )
const SOUND_PATTERN = Regex( ".+\\.($SOUND_EXTENSIONS)" )
# TODO eventually, add moment functionality for sounds
const MOMENT_PATTERN = Regex( ".+\\[.+\\].*\\.($IMG_EXTENSIONS|$MESH_EXTENSIONS)" )
const MOMENT_TAG_PATTERN = r".*\[.+\]"


struct AssetTemplateManifest

    templateName::String
    assetNames::Vector{AssetName}

    function AssetTemplateManifest(templateName, assetNames)
        # TODO: when additional sound functionality is added we'll remove this restriction
        checkArgument( length(soundNames) <= 1, "Too many OGG files for sprite template $templateName" )
        checkArgument( 0 != length(textureNames), "No sprite frame files found for $templateName" )
        if !(textureNames |> issorted)
            sort!(textureNames)
        end
        if !(soundNames |> issorted)
            sort!(soundNames)
        end
        return new( templateName, textureNames, soundNames )
    end
end


function preloadManifests() :: Dict{String, SpriteTemplateManifest}
    templateNames = readdir( spritePathBase )
    @info "Preloading $(length(templateNames)) SpriteTemplateManifests"
    return Dict( templateName => loadSpriteTemplateManifest(templateName) for templateName in templateNames )
end


function findTemplateName(assetPath::String)
    checkArgument( startswith( assetPath, spritePathBase ) && !endswith( assetPath, "/" ), "bad asset path $assetPath" )
    assetPathSplit =  split(assetPath, "/")
    return assetPathSplit[ lastindex(assetPathSplit) - 1 ]
end


# this is entirely different from the betamax code. the comps are much cleaner than the java reflections and not even slow.
# (of course we couldn't write it the way it's written in the java even if we wanted to.)
# this could also have been written with the filter function which might possibly be faster for large data sets
# however, for small test data sets it performs the same, and it requires a convert method which completely
# negates the type safety of the betamax TextureName and SoundFileName wrappers. As it is there are convert methods for
# going from TextureName/SoundFileName to String, but not the other way around.
function loadSpriteTemplateManifest(templateName::String)
    templatePathContents = readdir( spritePathBase * templateName )
    spriteFilenames = [ TextureName(filename) for filename in templatePathContents if occursin(IMG_PATTERN, filename) ]
    soundFilenames = [ SoundFileName(filename) for filename in templatePathContents if occursin(SOUND_PATTERN, filename) ]
    return SpriteTemplateManifest( templateName, spriteFilenames, soundFilenames )
end


function getMomentNamedTextures(manifest::SpriteTemplateManifest)
    return momentNamedTextures = [ textureName for textureName in manifest.textureNames if occursin( MOMENT_PATTERN, textureName.filename ) ]
end


function getMomentName(textureName::TextureName)
    if nothing != match( MOMENT_TAG_PATTERN, textureName.filename )
        return match( MOMENT_TAG_PATTERN, textureName.filename ).captures[1]
    end
    throw( ArgumentError("TextureName $textureName is not a moment named texture") )
end


# WARNING not entirely sure if this does what it should yet. we'll have to see it used in context first.
# the betamax code is java regex boilerplate packed inside a map function. I've translated it to the best
# of my ability but by no means literally. it's possible I've misunderstood what the java actually does.
function getMomentNames(manifest::SpriteTemplateManifest)
    momentNamedTextures = getMomentNamedTextures(manifest)
    if !( momentNamedTextures |> isempty )
        return momentNames = [ match( MOMENT_TAG_PATTERN, textureName.filename ).captures[1] for textureName in momentNamedTextures ]
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
    throw( ArgumentError("No moment named '$desiredMomentName' in $(manifest.templateName)") )
end
