using ModernGL, GLAbstraction
import Base.close

include("/home/gil/doomfish/doomfishjl/globalvars.jl")
include("LazyTextureImage.jl")
include("/home/gil/doomfish/doomfishjl/opengl/ShaderProgram.jl")
include("/home/gil/doomfish/doomfishjl/opengl/VAO.jl")
include("/home/gil/doomfish/doomfishjl/opengl/VBO.jl")

# TODO: definitely give this one a once-over. I was mostly asleep writing it

# A texture stored in opengl. But it can load and unload itself into and out of VRAM on demand transparently
# For methods beginning with name of "bt" bind() must be called first
mutable struct Texture # default values:
    handle::Union{ Int, Nothing }
    vramLoaded::Bool # false
    lazyTextureImage::LazyTextureImage
    boundTarget::Int # 0
    name::TextureName # lazyTextureImage.name

    function Texture( textureImage::LazyTextureImage )
        texture = new( nothing, false, textureImage, 0, textureImage.name )
        metrics.counters.virtualTexturesCounter += 1
        return texture
    end
end


function simpleTexture( textureName::TextureName, preLoaded::Bool ) :: Texture
    texture = Texture( LazyTextureImage(textureName) )
    if preloaded
        setRamLoaded(texture, true)
    end
    return texture
end


setRamLoaded( texture::Texture, loaded::Bool ) = setLoaded(texture.lazyTextureImage, loaded)
getRamLoaded( texture::Texture ) = return getLoaded(texture.lazyTextureImage)


function bind!( texture::Texture, target::Int )
    checkState( texture.vramLoaded, "Texture $texture vram not loaded" )
    checkState( texture.handle > 0, "Texture $texture has no opengl handle" )

    glBindTexture( target, handle )
    texture.boundTarget = target
end


function rebind( texture::Texture )
    # betamax: TODO: use glGet to ensure this is really the bound object. thanks opengl.

    checkArgument( 0 != texture.boundTarget, "call bind!() to set GL target first" )
    bind!( texture, texture.boundTarget )
end


function btSetParameters( texture::Texture )
    rebind( texture )
    # glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    # glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    # FIXME will this segfault?
    # glTexParameterfv(boundTarget, GL_TEXTURE_BORDER_COLOR, new float[]{1.0f, 0.5f, 0.8f, 0.5f});

    glTexParameteri( texture.boundTarget, GL_TEXTURE_WRAP_T, GL_REPEAT )
    glTexParameteri( texture.boundTarget, GL_TEXTURE_WRAP_T, GL_REPEAT )

    glTexParameteri( texture.boundTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR )
    glTexParameteri( texture.boundTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR )
end


function btUploadTextureUnit( texture::Texture )
    rebind(texture)
    uploadLazyGl( texture.lazyTextureImage, texture.boundTarget )
end


# betamax: (translated to julia)
# because BetamaxGlProgram.loopOnce calls close(RenderPhase) (which calls glfwPollEvents) in the same frame
# this should check against the same frame textures we JUST rendered, so we should
# never end up JIT loading just for a damn collision check
function isTransparentAtCoordinate( texture::Texture, coordinate::TextureCoordinate )
    if !getLoaded( texture.lazyTextureImage )
        @collectstats JIT_MOUSE_TEXTURE_LOADING begin
            @warn "Had to load texture just to process collision check: $texture"
            setLoaded( texture.lazyTextureImage, true )
        end
    end

    color = getPixel( texture.lazyTextureImage, coordinate )
    transparentEnough = isTransparentEnough(color)

    @info "$color |> isTransparentEnough = $transparentEnough"
    return transparentEnough
end


function render( texture::Texture, location::TextureCoordinate, shaderProgram::ShaderProgram )
    checkState( nothing != texture.vao && nothing != texture.vbo )

    if !texture.vramLoaded
        @warn "Uploading texture to VRAM at rendertime: $(texture.name)"
        metrics.counters.renderTimeUploadsCounter += 1
    end

    setVramLoaded!( texture, true )
    bind!( texture, GL_TEXTURE_2D )
    bindVAO(texture.vao)

    useProgram( shaderProgram )
    framebufferCoordinate = location |> toFramebufferCoordinate
    glUniform2f( getUniformLocation("translatePosition", shaderProgram), framebufferCoordinate.x, framebufferCoordinate.y )

    bindVBO( texture.vbo, GL_ARRAY_BUFFER )
    glClear( GL_DEPTH_BUFFER_BIT )

    # for drawing a texture flat to a 2D screen, we represent its rectangular bounds w/ two coplanar triangles
    glDrawArrays( GL_TRIANGLES, 0, 3 #=3 pts in a triangle=# * 2 #= * 2 triangles=# ) # = total vertices drawn

end


function prepareForDrawing()
    vbo = VBO()
    vao = VAO()
    bindVAO(vao)
    bindAndLoadVBO( vbo, GL_ARRAY_BUFFER, GL_DYNAMIC_DRAW, [
    # TODO: implement variable sprite positions
    # for now, left over from the mute days, all sprites are fullscreen w/ position (0,0)

    # two right triangles covering the whole screen
    # xpos   ypos      xtex  ytex
     -1.0f0,  1.0f0,     0.0f0, 1.0f0,
      1.0f0,  1.0f0,     1.0f0, 1.0f0,
     -1.0f0, -1.0f0,     0.0f0, 0.0f0,

      1.0f0,  1.0f0,     1.0f0, 1.0f0,
      1.0f0, -1.0f0,     1.0f0, 0.0f0,
     -1.0f0, -1.0f0,     0.0f0, 0.0f0,]
    )
    # the below wraps glVertexAttribPointer to make the argument types less annoying
    # (see VAO.jl)
    vertexAttribPointer( 0, 2, Float32, false, 4, 0 )
    vertexAttribPointer( 1, 2, Float32, false, 4, 2 )

end


function close( texture::Texture )
    setVramLoaded!( texture, false )
    close( texture.lazyTextureImage )
    metrics.counters.virtualTexturesCounter -= 1
end


function setVramLoaded!( texture::Texture, vramLoaded::Bool )
    if texture.vramLoaded == vramLoaded return end
    # betamax: TODO: if an exception causes this to fail the object will be in a bad state where it can't be closed either
    # whatever.
    texture.vramLoaded = vramLoaded
    if !vramLoaded vramUnload!(texture) end
    if vramLoaded vramLoad!(texture) end
end


function vramLoad!( texture::Texture )
    checkState( texture.handle == -1 )
    texture.handle = glGenTextures()
    checkState( texture.handle > 0 )

    bind!( texture, GL_TEXTURE_2D )
    btSetParameters( texture )
    btUploadTextureUnit( texture )

    metrics.counters.vramTexturesCounter += 1
    metrics.counters.vramImageBytesCounter += getByteCount( texture.lazyTextureImage )
end


function vramUnload!( texture::Texture )
    checkState( texture.handle > 0, "Texture $texture has no opengl handle" )
    glDeleteTextures( handle )
    texture.handle = -1
    metrics.counters.vramTexturesCounter -= 1
    metrics.counters.vramImageBytesCounter -= getByteCount( texture.lazyTextureImage )
end
