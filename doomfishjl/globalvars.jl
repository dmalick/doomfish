include("metrics/Metrics.jl")


# TODO: do I even need to say it


mainScript = ""

pausedTextureFile = ""
loadingTextureFile = ""
crashTextureFile = ""

metrics = Metrics( Counters(),  Dict{String, TimedStats}() )

# constants

# WARNING! The hard-coded UUID below defines the namespace
# for GENERATING and RETRIEVING texture file IDs.
# Changing will result in nullification of the entire texture cache!
const textureCacheNamespace = "c3fabaa7-2973-4de2-9511-a7c022f329b6"

const spritePathBase = "/home/gil/doomfishdata/data/sprites/"
const shaderPathBase = "/home/gil/doomfishdata/shaders/"

const textureCacheDir = "/home/gil/doomfishdata/data/texturecache/"
const textureKeyFilename = "$(textureCacheDir)texturekey.dat"
const manifestsPackageFilename = "/home/gil/doomfishdata/data/manifestsPackage.dat"
const usePrecompiledManifests = true
const textureMaxFramesForResidentMemoryStrategy = 10
const texturePreloadFrameLookahead = 16


# state variables

startFullscreen = false

showSystemCursor = false
enableSound = true

targetFps = 30
