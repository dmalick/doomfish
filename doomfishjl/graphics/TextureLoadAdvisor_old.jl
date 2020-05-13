using Logging

struct TextureLoadAdvisor
    getMostNeededTextures::Function
    getLeastNeededTextures::Function
end
function TextureLoadAdvisor()
    return TextureLoadAdvisor(getMostNeededTextures, getLeastNeededTextures)
end
# the methods below mimic a java interface, in that they must be overriden to behave properly,
# or do anything at all except crash the program.
# of course the safety offered by the java isn't here, so proceed with caution.

# betamax:
# Implementor must be threadsafe for TextureLoadAdvisor methods, will be called from another thread
# Interface for advising TextureRegistry on what textures could be loaded next


# WARNING: override this method w/ getMostNeededTextures(frameLookahead::Int)
# Return an ordered list of the most urgently needed textures.
# All parameters are basically performance advice.
#  - frameLookahead: look ahead this many frames
function getMostNeededTextures(args...) error("implement method getMostNeededTextures(frameLookahead::Int)") end
#getMostNeededTextures(args...) = return getMostNeededTextures()


# WARNING: override this method w/ getLeastNeededTextures(frameLookahead::Int, maxVictims::Int, candidates::Vector{TextureName})
# Return an ordered list of the least urgently needed textures. All parameters are basically performance advice,
# if it is somehow easier to partially ignore them and return a list of any size, then whatever works is fine.
#  - frameLookahead: Look ahead this many frames
#  - maxVictims: No more than this many need be returned.
#  - candidates: Restrict yourself to these candidates.
function getLeastNeededTextures(args...) error("implement method getLeastNeededTextures(frameLookahead::Int, maxVictims::Int, candidates::Vector{TextureName})")
end
