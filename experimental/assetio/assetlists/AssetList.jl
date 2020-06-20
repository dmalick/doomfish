include("/home/gil/doomfish/doomfishjl/assets/assetfilepatterns.jl")
include("/home/gil/doomfish/doomfishjl/assets/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/doomfishtool.jl")
include("/home/gil/doomfish/doomfishjl/globalvars.jl")


@interface AssetList begin
    templateName::String
end


# function getMomentName(textureName::TextureName)
#     if nothing != match( MOMENT_TAG_PATTERN, textureName.filename )
#         return match( MOMENT_TAG_PATTERN, textureName.filename ).captures[1]
#     end
#     throw( ArgumentError("TextureName $textureName is not a moment named texture") )
# end
