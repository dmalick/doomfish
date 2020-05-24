
include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/imageio/ColorSample.jl")
include("/home/gil/doomfish/doomfishjl/imageio/TextureImage.jl")
include("/home/gil/doomfish/doomfishjl/imageio/TextureImagesIO.jl")
include("/home/gil/doomfish/doomfishjl/opengl/coordinates.jl")
include("AssetProxy.jl")

# betamax:
#=  A proxy for a TextureImage that may or may not actually be loaded into RAM at any given time
    Must be unloaded in the main thread! Can be loaded from any thread.
 =#


struct LazyTextureImage <: AssetProxy
    # betamax: TODO get rid of this lock
    # we'll see
    LOCK::ReentrantLock
    textureImage::Union{TextureImage, Nothing}
    name::TextureName
    function LazyTextureImage(name::TextureName)
        return new( ReentrantLock(), nothing, name )
    end
end


function uploadLazyGl(ltimage::LazyTextureImage, boundTarget::Int)
     lock(ltimage.LOCK)
     checkLoaded(ltimage)
     uploadTextureImageGl( ltimage.textureImage, boundTarget )
     unlock(ltimage.LOCK)
end


function getPixel(ltimage::LazyTextureImage, coordinate::TextureCoordinate) :: ColorSample
    lock(ltimage.LOCK)
    checkLoaded(ltimage)
    pixel =  getTexturePixel( ltimage.textureImage, coordinate )
    unlock(ltimage.LOCK)
    return pixel
end


function getByteCount(ltimage::LazyTextureImage) :: Int
    lock(ltimage.LOCK)
    checkLoaded(ltimage)
    return getByteCount( ltimage.textureImage )
    unlock(ltimage.LOCK)
end


close(ltimage::LazyTextureImage) = unload(ltimage)


function setLoaded(ltimage::LazyTextureImage, loadState::Bool)
    if loadState == getLoaded(ltimage)
        return
    end
    if loadState # == true
        load(ltimage)
    else
        unload(ltimage)
    end
end


function getLoaded(ltimage::LazyTextureImage)
    # betamax:
    # FIXME this will cause a block if another thread is partly done with loading.
    # also unloading but that's not a big deal because unloading is very fast
    # this also means our timers to catch late loads won't be accurate because the
    # late loading is hidden inside the getLoaded call
    lock(ltimage.LOCK)
    return nothing != ltimage.textureImage
    unlock(ltimage.LOCK)
end


function load(ltimage::LazyTextureImage)
    newImage = textureImageFromFile( ltimage.name )
    lock(ltimage.LOCK)
    # betamax:
    # prevent leaks due to double load
    # this should never happen or at least be rare enough that doing the extra pointless load work
    # is not a major deal, certainly not worth holding the lock the whole time and slowing checkLoaded
    if nothing != ltimage.textureImage close(newImage)
    else ltimage.textureImage = newImage end
    unlock(ltimage.LOCK)
end


function unload(ltimage::LazyTextureImage)
    lock(ltimage.LOCK)
    if getLoaded(ltimage)
        close( ltimage.textureImage )
        ltimage = nothing
    end
    unlock(ltimage.LOCK)
end


function checkLoaded(ltimage::LazyTextureImage)
    if !getLoaded(ltimage)
        @error "Runtime RAM load: $(ltimage.name)"
    end
    setLoaded( ltimage, true )
end
