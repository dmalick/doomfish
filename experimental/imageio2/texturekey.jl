using UUIDs, Serialization
include("/home/gil/.atom/doomfishjl/globalvars.jl")
include("ImageIO.jl")

struct TextureKey
    textureNames::Array{String}
    cachedNames::Array{UUID}
    textureKey::Dict{String, UUID}
end
function loadTextureKey()
    if !isfile(textureKeyFilename
        return TextureKey([],[],Dict())
    end
    return deserialize(textureKeyFilename)
end

function saveTextureKey(textureKey::TextureKey)
    serialize(textureKeyFilename, textureKey)
end

function addTexture(textureKey::TextureKey, image::SparseImage)
    append!(textureKey.textureNames, image.imageFilename)

end
