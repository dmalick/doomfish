using ModernGL, UUIDs, Logging
include("/home/gil/doomfish/pseudointerface/interface/utils.jl")
include("opengl/typeEquivalencies.jl")
include("globalvars.jl")
include("opengl/GlErrorCodes.jl")
include("assetnames.jl")

filepattern = r".+\..+"
jlpattern = r".+\.jl"
extpattern = r"\..+"

includeDir( dir::String ) = include.( [ dir*file for file in readdir(dir) if occursin( filepattern, file ) ] )

function includeFiles( dir::String; ext::String=".jl" )
    checkArgument( occursin(extpattern, ext), "invalid file extension: $ext" )
    include.( [ dir*file for file in readdir(dir) if occursin( Regex(".+$(ext)"), file ) ] )
end

function includeFiles( dir::String, files::String... )
    include.( [dir*file for file in files if occursin(filepattern, file)] )
end


# note that any object we want to force freeing memory of must be allowed to have a value of nothing.
# i.e. if we want to free an Int64 its declared type should be Union{Int64, Nothing}.
# also note that the garbage collector can be pretty slow.
# it may be sufficient to set the object's value to nothing and wait for the garbage collector to do its thing.
function freeMem(obj)
    obj = nothing
    GC.gc()
end


# convenience functions for safety checks

function checkGlError()
    err = glGetError()
    if 0 != err
        error( "checkGlError failed: $(GlErrorCode(err)) ( GlErrorCode $err )" )
    end
end


macro checkGlError(expr)
    checkArgument( expr isa Expr, "@checkGlError only operates on function calls, macro calls, or begin blocks (got $expr)")
    checkArgument( expr.head in (:call, :block, :macrocall), "@checkGlError only operates on function calls, macro calls, or begin blocks (got $expr)")
    return esc( quote
        checkGlError()
        $expr
        checkGlError()
    end )
end


function getGlErrors()
    errors = []
    while (errorcode = glGetError()) != GL_NO_ERROR
        push!( errors, errorcode )
        push!( errors, "\n" )
    end
    return errors
end


function debugMessageCallback( source::UInt32, type::UInt32, id::UInt32, severity::UInt32, length::Int, message::String, userParam::Ptr{Nothing} )
    if type == GL_DEBUG_TYPE_ERROR @error "opengl error: $message"
    else @debug "opengl debug: $message" end
end



# time and sleep ftns

# the below collectstats macro is more accurately a "collecttimes" macro, named this
# temporarily b/c I don't want to have to hunt down every instance of @collectstats
# and change it over. the original @collectstats collects verbose stats from @timed
# and saves them all. this would eventually eat up a lot of memory, so I don't want
# to use it until performance testing.
macro collectstats( statsName, body )
    checkArgument( statsName isa Symbol && ( name = eval(statsName) ) isa StatsName, "1st arg to @collecttimes must be a StatsName" )
    checkArgument( body isa Expr && body.head in (:call, :block, :macrocall, :->), "2nd arg to @collecttimes must be a function, macrocall, or begin block (got $body)" )

    checkKeyCall = esc(:( if !haskey( metrics.timeStats, $name ) metrics.timeStats[$name] = TimeStats() end ))
    updateCall = esc(:( updateStats!(metrics.timeStats[$name], @timed( $body )...) ))

    return quote
        $checkKeyCall
        $updateCall
    end
end


# all times in betamax are given in milliseconds, so it's helpful to have a function
# to give us time in millis rather than seconds or nanos
# WARNING / TODO: there's still probably some code kicking around using nanoseconds
time_ms() = ceil( time() * 1000 ) |> Int64


# why the hell not
time_μs() = ceil( time() * 10^6 ) |> Int64


# TODO: test the below thoroughly
# betamax uses a java long type so we're casting this argument Int64 explicitly
function sleepUntilPrecisely(targetTime::Int64) :: Bool
    # betamax:
    # if we are more than 5 ms out, [sleep] is good enough
    # only sleep for a third of the time we have left to conservatively account for inaccuracy
    if time_ms() >= targetTime return false end
    targetSleep = targetTime - time_ms()
    while targetSleep > 5
        # WARNING: betamax wraps the below in a try block w/ a catch(InterruptedException)
        # I don't know that there is a Julia equivalent, leaving it naked for now
        sleep( targetSleep / 3000 ) # sleep ftn takes seconds, we're in millis
        targetSleep = targetTime - time_ms()
    end
    #= betamax:
    now that we're pretty close to it, busy loop
    FIXME currentTimeMillis probably makes a system call, possibly increasing chance of being unscheduled
    it would be worth researching whether this is actually how modern schedulers on linux and windows work
    or not, and if so, use a self calibrated busy loop to reduce our system calls
    or like i dunno, something.
    =#
    while time_ms() < targetTime continue end
    return true
end



# opengl graphics related functions

function drawElements(mode, count, type, indices)
    glDrawElements( mode, count, typeEquivalencies[type], Ptr{Nothing}( indices*sizeof(type) ) )
end



# asset cache IO functions

function readCached(key::String...) :: Union{IOStream, Nothing}
    filename = cachedFilename(key)
    if !isfile(filename)
        return nothing
    end
    return open(filename, read=true)
end


function writeCached(overwrite::Bool, key::String...) :: IOStream
    println(key)
    if overwrite
        return open( cachedFilename(key), create=true, truncate=true, write=true )
    else
        return open( cachedFilename(key), create=true, write=true )
    end
end


function cachedFilename(key::String...)
    strings = ""
    for str in key
        strings *= str
        strings *= "\n"
    end
    # WARNING! The hard-coded UUID below defines the namespace
    # for GENERATING and RETRIEVING asset file IDs.
    # Changing will result in nullification of the entire asset cache!
    uuid = uuid5( UUID("c3fabaa7-2973-4de2-9511-a7c022f329b6"), strings )
    return textureCacheDir*string(uuid)*".dat"
end

cachedFilename(key::Tuple) = cachedFilename(key...)



function putifexists( collection::AbstractDict, containerType::Type{T}, key, value ) where T <: AbstractArray
    if !haskey( collection, key ) collection[key] = containerType() end
    push!( collection[key], value )
end


putifexists( collection::AbstractDict, key, value ) = putifexists( collection, typeof(collection).parameters[2], key, value )
