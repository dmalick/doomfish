using UUIDs, Dates

include("/home/gil/doomfish/doomfishjl/assetnames.jl")
include("/home/gil/doomfish/doomfishjl/sprite/Clickability.jl")
include("/home/gil/doomfish/doomfishjl/opengl/coordinates.jl")


struct SpriteSnapshot
    template::SpriteTemplate
    name::SpriteName
    creationSerial::Int
    initialFrame::Int
    clickability::Clickability
    layer::Int
    repetitions::Int
    pinnedToCursor::Bool
    paused::Bool
    hidden::Bool
    pausedFrame::Int
    location::TextureCoordinate
end


struct GameplaySnapshot
    globalShader::String
    currentFrame::Int
    sprites::Vector{SpriteSnapshot}
    scriptVariables::Dict{String,String}
    creationDate::Date
    # betamax: String mnemonicName = NAME_GENERATOR.next();
    name::String
    function GameplaySnapshot(globalShader, currentFrame, sprites, scriptVariables, creationDate,
                     name)
        return new( globalShader, currentFrame, sprites, scriptVariables, creationDate,
                         String(creationDate) * String( UUID( "cb1d482e-122e-4243-9926-3878a0ec3772") ), String(creationDate) )
    end
end


function writeToFile(snapshot::GameplaySnapshot)
    outputStream = getMappedFile( snapshot.name )
    serialize( outputStream, snapshot )
    return outputStream
end


function getMappedFile(name::String)
    # TODO: maybe change this file extension
    return open( snapshotDir::String*name*".json", create=true, read=true, write=true )
end


function readFromFile(filename::String)
    inputStream = open(filename)
    return deserialize(filename)
end
