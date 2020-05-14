
include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("/home/gil/doomfish/doomfishjl/imageio/ManifestsPackage.jl")
include("/home/gil/doomfish/doomfishjl/graphics/SpriteTemplate.jl")
# include("/home/gil/doomfish/doomfishjl/sound/Sound Registry") # TODO: implement sound eventually  >:(


struct SpriteTemplateRegistry
    # soundRegistry::SoundRegistry
    registeredTemplates::Dict{String,SpriteTemplate}
    registeredManifests::Dict{String,SpriteTemplateManifest}
    textureRegistry::TextureRegistry
end


preloadCompiledManifests() = return readManifestsPackageFromFile().manifestsDict


# betamax:
# This preloads manifests and sound, actual images of course are not actually loaded.
 # This should take a negligible amount of time if there are no sounds, a couple seconds maybe (wild guess)
 # (It's definitely worth it to avoid having to do any IO when sprites are created)
 # If there are sounds, add 10-15 seconds per hour of OGG sound roughly.
 # It'd be nice to load OGG sound dynamically so we can avoid adding ten seconds to boot time,
 # but it's not the end of the world if there is and there was no time in the shipping schedule for that
function preloadTemplates(str::SpriteTemplateRegistry)
    # TODO: writing out "spriteTemplateRegistry" every time is annoying and makes things
    # hard to read. Maybe make a macro to unpack struct variable names into the scope, java style
    checkArgument( str.registeredManifests |> length == 0 )
    checkArgument( str.registeredTemplates |> length == 0 )
    @info "Preloading all sprite template manifests and sounds"
    if usePrecompiledManifests
        try
            @info "Using precompiled manifests file $(manifestsPackageFilename)"
            @info "Compiling manifests from resources"
            merge!( str.registeredManifests, preloadCompiledManifests() )
        catch
            @error "Could not load Global.manifestsPackageFilename: $(manifestsPackageFilename)"
        end
    else
        @info "Compiling manifests from resources"
        merge!( str.registeredManifests, preloadManifests() )
    end
    for manifest in ( str.registeredManifests |> values )
        template = SpriteTemplate( manifest, str.textureRegistry )
        str.registeredTemplates[manifest.templateName] = template
        loadedSpriteTemplatesCounter += 1
        # loadSoundBuffer(template, str.soundRegistry) # TODO: sound
    end
    @info "Completed all sprite template preloading"
end

# betamax:
# TODO it might be nice to have some mechanism by which templates not used for a while are unloaded
# that said it probably makes sense to have that partially manually controlled (to group templates into
# dayparts for example) rather than entirely automagical, especially since the performance implications are
# quite serious if the magic gets it wrong
# conversely, automatic background loading of things that will be needed in the future might be worthwhile

function getTemplate(str::SpriteTemplateRegistry, name::String) :: SpriteTemplate
    if !haskey(str.registeredTemplates, name)
        template = SpriteTemplate( getManifest(name), str.textureRegistry )
        # betamax:
        # TODO this does not allow for lazy sound loading because if it is not loaded into the SpriteTemplate by
        # the time the Sprite is created the Sprite/SpriteTemplate have no soundRegistry access to load the
        # soundbuffer

        # loadSoundBuffer(template, str.soundRegistry) # TODO: sound
        str.registeredTemplates[name] = template
        mertics.counters.loadedSpriteTemplateCounter += 1
    else
        template = str.registeredTemplates[name]
    end
    return template
end


function getManifest(str::SpriteTemplateManifest, name::String)
    if !haskey( str.registeredManifests, name )
        manifest = loadSpriteTemplateManifest(name)
        str.registeredManifests[name] = manifest
    else
        manifest = str.registeredManifests[name]
    end
end

function close(str::SpriteTemplateRegistry)
    mertics.counters.loadedSpriteTemplatesCounter -= length(str.registeredTemplates)
    for template in ( str.registeredTemplates |> values )
        close(template)
    end
    # close(soundRegistry) TODO: sound
end

function getNamedMoment(str::SpriteTemplateManifest, emplateName::String, momentName::String)
    return getManifest(str, templateName) |> getMomentIDByName
end
