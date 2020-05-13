using CodecLz4
includepath("doomfishjl/doomfishtool.jl")
includepath("doomfishjl/globalvars.jl")

LZ4_BUFFER = IOBuffer()
BUFFER_CAPACITY = typemax(Int)


function getStaticBuffer() ::IOBuffer
    seekstart(LZ4_BUFFER)
    LZ4_BUFFER.maxsize = BUFFER_CAPACITY
    return LZ4_BUFFER
end


function compress(bytePixelData::IOBuffer) ::IOBuffer
    lz4Buffer = getStaticBuffer()
    compressedByteCount = write( lz4Buffer, transcode( LZ4FrameCompressor, bytePixelData.data ) )

    checkState( 0 != compressedByteCount, "LZ4 compression failed" )
    seekstart( lz4Buffer )

    lz4Buffer.size = compressedByteCount
    lz4Buffer.maxsize = lz4Buffer.size

    return lz4Buffer
end


function decompress(readStream::IOStream, expectedBytes::Int) ::IOBuffer
    @assert expectedBytes > 0
    lz4Buffer = getStaticBuffer()

    memoryDecompressStats = @timed begin

        decompressedByteCount =  write( lz4Buffer, LZ4FrameDecompressorStream(readStream) |> read )
        checkState( decompressedByteCount == expectedBytes, "lz4 decompression failed: $decompressedByteCount" )

        seekstart( lz4Buffer )
        lz4Buffer.size = decompressedByteCount
        lz4Buffer.maxsize = lz4Buffer.size

    end
    updateTimedStats!( metrics, MEMORY_DECOMPRESSION, memoryDecompressStats )
    return lz4Buffer
end




# the decompress method below is for testing purposes only. it never really gets used

function decompress(compressedPixelData::IOBuffer, expectedBytes::Int) ::IOBuffer
    @assert expectedBytes > 0
    lz4Buffer = getStaticBuffer()
    memoryDecompressStats = @timed begin
        decompressedByteCount =  write(lz4Buffer, transcode(LZ4FrameDecompressor, compressedPixelData))
        checkState(decompressedByteCount == expectedBytes, "lz4 decompression failed: $decompressedByteCount")
        #@assert decompressedByteCount == expectedBytes
        seekstart(lz4Buffer)
        lz4Buffer.size = decompressedByteCount
        lz4Buffer.maxsize = lz4Buffer.size
    end
    updateTimedStats!( metrics, MEMORY_DECOMPRESSION, memoryDecompressStats )
    return lz4Buffer
end
