include("metrics/Metrics.jl")


# TODO: do I even need to say it


mainScript = ""

pausedTextureFile = ""
loadingTextureFile = ""
crashTextureFile = ""

metrics = Metrics()

program = nothing

# constants

const textureCacheKey = "TextureImages#textureImageFromFile;lz4"
const meshCacheKey = "Mesh#meshFromFile;lz4"
const soundCacheKey = "Sound#soundFromFile;lz4"

# WARNING! The hard-coded UUID below defines the namespace
# for GENERATING and RETRIEVING asset file IDs.
# Changing will result in nullification of the entire asset cache!
const assetCacheNamespace = "c3fabaa7-2973-4de2-9511-a7c022f329b6"

const modelPathBase = "/home/gil/doomfishdata/data/models/"
const spritePathBase = "/home/gil/doomfishdata/data/sprites/"
const soundPathBase = "/home/gil/doomfishdata/data/sounds/"
const shaderPathBase = "/home/gil/doomfishdata/shaders/"
const resourcePathBase = "/home/gil/doomfish/resources/"

const textureCacheDir = "/home/gil/doomfishdata/data/texturecache/"
const textureKeyFilename = "$(textureCacheDir)texturekey.dat"


# XXX haven't decided whether to go w/ the naming scheme "manifest" or "assetList"

const manifestsPackageFilename = "/home/gil/doomfishdata/data/manifestsPackage.dat"
const usePrecompiledManifests = true

const assetListsPackageFilename = "/home/gil/doomfishdata/data/assetListsPackage.dat"
const usePrecompiledAssetLists = true


const textureMaxFramesForResidentMemoryStrategy = 10
const texturePreloadFrameLookahead = 16

const defaultGlobalShaderName = nothing

# state variables

debugMode = false

startFullscreen = false

showSystemCursor = false
enableSound = true

targetFps = 30
