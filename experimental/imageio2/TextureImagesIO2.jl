using ModernGL, Logging
include("TextureImage.jl")
include("TextureName.jl")

CACHE_KEY() = return "TextureImages#fromRgbaFile;lz4"
BANDS() = return 4

# TODO: finish out below loadCached function
function loadCached(filename::String) :: Union{TextureImage, Nothing}
    readStream = readCached(CACHE_KEY(), filename)
    if readStream != nothing
        @info "Loading from cache: $filename"
        # return loadFromChannel(filename, fileReadStream)
    else
        return nothing
    end
end

# original betamax name loadFromChannel
function loadFromStream(filename::String, readStream::IOStream) :: Union{TextureImage, Nothing}
    # betamax code has a whole lot of bytebuffer mess to work out

end

function cachedFilenameFromTexture(textureName::TextureName)
    return cachedFilename((CACHE_KEY(), textureName.filename))
end
