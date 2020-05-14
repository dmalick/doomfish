using Logging

include("/home/gil/doomfish/pseudointerface/interface.jl")

@interface TextureLoadAdvisor begin
    # betamax:
    # Implementor must be threadsafe for TextureLoadAdvisor methods, will be called from another thread
    # Interface for advising TextureRegistry on what textures could be loaded next
end

# override w/ getMostNeededTextures(advisor::T, frameLookahead::Int) where T <: TextureLoadAdvisor
# Return an ordered list of the most urgently needed textures.
# All parameters are basically performance advice.
#  - frameLookahead: look ahead this many frames
@abstractMethod(TextureLoadAdvisor, getMostNeededTextures)

# TODO: getLeastNeededTextures
# override w/ getLeastNeededTextures(frameLookahead::Int, maxVictims::Int, candidates::Vector{TextureName})
# Return an ordered list of the least urgently needed textures. All parameters are basically performance advice,
# if it is somehow easier to partially ignore them and return a list of any size, then whatever works is fine.
#  - frameLookahead: Look ahead this many frames
#  - maxVictims: No more than this many need be returned.
#  - candidates: Restrict yourself to these candidates.
# @abstractMethod(TextureLoadAdvisor, getLeastNeededTextures)
