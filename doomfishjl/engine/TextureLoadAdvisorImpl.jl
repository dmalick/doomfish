include("includepath.jl")
includepath("doomfishjl/graphics/SpriteTemplateRegistry.jl")
includepath("doomfishjl/sprite/SpriteRegistry.jl")
includepath("doomfishjl/assetnames.jl")


struct TextureLoadAdvisorImpl <: TextureLoadAdvisor
    spriteRegistry::SpriteRegistry
    spriteTemplateRegistry::SpriteTemplateRegistry
end


function getMostNeededTextures(advisor::TextureLoadAdvisorImpl, frameLookahead::Int)
    needed = Vector{TextureName}()
    neededSet = Set{TextureName}()
    for framesAhead in 1:frameLookahead
        for sprite in ( advisor.spriteRegistry |> getSpritesInRenderOrder )
            textureName = getTextureName( sprite, framesAhead )
            if !(textureName in neededSet) push!( needed, textureName ) end
            push!( neededSet, textureName )
        end
    end
    return needed
end

# TODO: getLeastNeededTextures
