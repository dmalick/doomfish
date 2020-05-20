
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("/home/gil/doomfish/doomfishjl/imageio/β_imageio/β_ManifestsPackage.jl")
include("/home/gil/doomfish/doomfishjl/graphics/SpriteTemplate.jl")

# include("/home/gil/doomfish/doomfishjl/sound/Sound Registry") # TODO: implement sound eventually  >:(



# soundRegistry::SoundRegistry
registeredTemplates = Dict{String,SpriteTemplate}()
registeredManifests = Dict{String,SpriteTemplateManifest}()


# betamax:
# This preloads manifests and sound, actual images of course are not actually loaded.
 # This should take a negligible amount of time if there are no sounds, a couple seconds maybe (wild guess)
 # (It's definitely worth it to avoid having to do any IO when sprites are created)
 # If there are sounds, add 10-15 seconds per hour of OGG sound roughly.
 # It'd be nice to load OGG sound dynamically so we can avoid adding ten seconds to boot time.
function preloadTemplates()

    checkArgument( registeredManifests |> length == 0 )
    checkArgument( registeredTemplates |> length == 0 )
    @info "Preloading all sprite template manifests and sounds"
    if usePrecompiledManifests
        try
            @info "Using precompiled manifests file $(manifestsPackageFilename)"
            @info "Compiling manifests from resources"
            merge!( registeredManifests, readManifestsPackageFromFile() )
        catch
            @error "Could not load Global.manifestsPackageFilename: $(manifestsPackageFilename)"
        end
    else
        @info "Compiling manifests from resources"
        merge!( registeredManifests, preloadEverything() )
    end
    for manifest in ( registeredManifests |> values )
        template = SpriteTemplate( manifest, textureRegistry )
        registeredTemplates[manifest.templateName] = template
        loadedSpriteTemplatesCounter += 1
        # loadSoundBuffer(template, soundRegistry) # TODO: sound
    end
    @info "Completed all sprite template preloading"
end

# betamax:
# TODO it might be nice to have some mechanism by which templates not used for a while are unloaded
# that said it probably makes sense to have that partially manually controlled (to group templates into
# dayparts for example) rather than entirely automagical, especially since the performance implications are
# quite serious if the magic gets it wrong
# conversely, automatic background loading of things that will be needed in the future might be worthwhile

function getTemplate(name::String) :: SpriteTemplate
    if !haskey(registeredTemplates, name)
        template = SpriteTemplate( getManifest(name), textureRegistry )
        # betamax:
        # TODO this does not allow for lazy sound loading because if it is not loaded into the SpriteTemplate by
        # the time the Sprite is created the Sprite/SpriteTemplate have no soundRegistry access to load the
        # soundbuffer

        # loadSoundBuffer(template, soundRegistry) # TODO: sound
        registeredTemplates[name] = template
        mertics.counters.loadedSpriteTemplateCounter += 1
    else
        template = registeredTemplates[name]
    end
    return template
end


function getManifest(name::String)
    if !haskey( registeredManifests, name )
        manifest = loadSpriteTemplateManifest(name)
        registeredManifests[name] = manifest
    else
        manifest = registeredManifests[name]
    end
end

function closeSpriteTemplateRegistry()
    mertics.counters.loadedSpriteTemplatesCounter -= length(registeredTemplates)
    for template in ( registeredTemplates |> values )
        close(template)
    end
    # close(soundRegistry) TODO: sound
end

function getNamedMoment(templateName::String, momentName::String)
    return getManifest(templateName) |> getMomentIDByName
end
