include("/home/gil/doomfish/pseudointerface/interface/Interface.jl")

@interface Asset begin
    byteData::IOBuffer
    filename::String
    unloaded::Bool
end
