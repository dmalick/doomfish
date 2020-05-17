using Statistics
import Base.iterate, Base.length, Base.GC_Diff
include("StatsName.jl")


@enum StatsFieldName begin
    TIMES
    BYTES
    GCTIMES
    MEMALLOCS
end


mutable struct Stats
    name::StatsName
    times::Vector{Float64}
    bytes::Vector{Int}
    gctimes::Vector{Float64}
    memallocs::Vector{Base.GC_Diff}
end
Stats(name::StatsName) = Stats(name, Vector{Float64}(), Vector{Int}(), Vector{Float64}(), Vector{Base.GC_Diff}())


function StatsMemallocAnalysis(Stats::Stats)
    checkState(!isempty(Stats.memallocs), "Stats object $(Stats.name) has no recorded memalloc values")
    memallocValues = [ [Stats.memallocs[i].:($field) for i in 1:length(Stats.memallocs)] for field in fieldnames(GC_Diff) ]
    #memallocValues = [ [testStats.memallocs[i].:($field) for i in 1:length(testStats.memallocs)] for field in fieldnames(GC_Diff) ]
    meanMemallocValues = ceil.(mean.(memallocValues))
    return Dict(
                "memallocValuesAvg" => GC_Diff(meanMemallocValues...),
                "memallocValuesMedian" => GC_Diff(median.(memallocValues)...),
                "memallocValuesStDev" => GC_Diff(ceil.(stdm.(memallocValues, meanMemallocValues))...),
                "memallocValuesVariance" => GC_Diff(ceil.(varm.(memallocValues, meanMemallocValues))...)
                )
end


# TODO: maybe wrap this crap in an enum
function StatsAnalysis(Stats::Stats)
    meanTime = Stats.times |> mean
    meanBytes = Stats.bytes |> mean
    meanGCtimes = Stats.gctimes |> mean
    return merge(
                Dict(
                "timeAvg" => meanTime,
                "timeMedian" => median(Stats.times),
                "timeStDev" => stdm(Stats.times, meanTime),
                "timeVariance" => varm(Stats.times, meanTime),

                "bytesAvg" => meanBytes,
                "bytesMedian" => median(Stats.bytes),
                "bytesStDev" => stdm(Stats.bytes, meanBytes),
                "bytesVariance" => varm(Stats.bytes, meanBytes),

                "gctimesAvg" => meanGCtimes,
                "gctimesMedian" => median(Stats.gctimes),
                "gctimesStDev" => stdm(Stats.gctimes, meanGCtimes),
                "gctimesVariance" => varm(Stats.gctimes, meanGCtimes),

                    ),
                StatsMemallocAnalysis(Stats)
                )
end


# function StatsAnalysis(Stats::Stats, StatsField::Vector)
#     fields = Dict(Stats.times => "times", Stats.bytes => "bytes", Stats.gctimes => "gctimes")
#     checkState(!isempty(StatsField), "Stats object $(Stats.name) has no recorded $(fields[StatsField]) values")
#     fieldMean = StatsField |> mean
#     return Dict(
#                 "$(fields[StatsField])Avg" => fieldMean,
#                 "$(fields[StatsField])Median" => median(StatsField),
#                 "$(fields[StatsField])StDev" => stdm(StatsField, fieldMean),
#                 "$(fields[StatsField])Variance" => varm(StatsField, fieldMean)
#                 )
# end
#
# StatsAnalysis(Stats::Stats, timeStatsField::Vector{GC_Diff}) = StatsMemallocAnalysis(Stats)

function StatsAnalysis(Stats::Stats, StatsFieldName::StatsFieldName)
    if StatsFieldName == MEMALLOCS
        return StatsMemallocAnalysis(Stats)
    end
    # checkState(StatsFieldName == "times" || StatsFieldName == "bytes" || StatsFieldName == "gctimes", """ "$StatsFieldName" is not a valid Stats field name.
    # valid field names are: "times", "bytes", "gctimes", MEMALLOCS """)

    fields = Dict(TIMES => Stats.times, BYTES => Stats.bytes, GCTIMES => Stats.gctimes)
    checkState(haskey(fields, StatsFieldName), """ '$StatsFieldName' is not a valid Stats field name.
    valid field names are: TIMES, BYTES, GCTIMES, MEMALLOCS """)
    checkState(!isempty(fields[StatsFieldName]), "Stats object $(Stats.name) has no recorded $(StatsFieldName |> lowercase) values")
    fieldMean = fields[StatsFieldName] |> mean

    return Dict(
                "$(StatsFieldName |> lowercase)Avg" => fieldMean,
                "$(StatsFieldName |> lowercase)Median" => median(fields[StatsFieldName]),
                "$(StatsFieldName |> lowercase)StDev" => stdm(fields[StatsFieldName], fieldMean),
                "$(StatsFieldName |> lowercase)Variance" => varm(fields[StatsFieldName], fieldMean)
                )
end
