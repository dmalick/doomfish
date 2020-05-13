using Statistics
import Base.iterate, Base.length, Base.GC_Diff
include("TimedStatsName.jl")


@enum TimedStatsFieldName begin
    TIMES
    BYTES
    GCTIMES
    MEMALLOCS
end


mutable struct TimedStats
    name::TimedStatsName
    times::Vector{Float64}
    bytes::Vector{Int}
    gctimes::Vector{Float64}
    memallocs::Vector{Base.GC_Diff}
end
TimedStats(name::TimedStatsName) = TimedStats(name, Vector{Float64}(), Vector{Int}(), Vector{Float64}(), Vector{Base.GC_Diff}())


function timedStatsMemallocAnalysis(timedStats::TimedStats)
    checkState(!isempty(timedStats.memallocs), "TimedStats object $(timedStats.name) has no recorded memalloc values")
    memallocValues = [ [timedStats.memallocs[i].:($field) for i in 1:length(timedStats.memallocs)] for field in fieldnames(GC_Diff) ]
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
function timedStatsAnalysis(timedStats::TimedStats)
    meanTime = timedStats.times |> mean
    meanBytes = timedStats.bytes |> mean
    meanGCtimes = timedStats.gctimes |> mean
    return merge(
                Dict(
                "timeAvg" => meanTime,
                "timeMedian" => median(timedStats.times),
                "timeStDev" => stdm(timedStats.times, meanTime),
                "timeVariance" => varm(timedStats.times, meanTime),

                "bytesAvg" => meanBytes,
                "bytesMedian" => median(timedStats.bytes),
                "bytesStDev" => stdm(timedStats.bytes, meanBytes),
                "bytesVariance" => varm(timedStats.bytes, meanBytes),

                "gctimesAvg" => meanGCtimes,
                "gctimesMedian" => median(timedStats.gctimes),
                "gctimesStDev" => stdm(timedStats.gctimes, meanGCtimes),
                "gctimesVariance" => varm(timedStats.gctimes, meanGCtimes),

                    ),
                timedStatsMemallocAnalysis(timedStats)
                )
end


# function timedStatsAnalysis(timedStats::TimedStats, timedStatsField::Vector)
#     fields = Dict(timedStats.times => "times", timedStats.bytes => "bytes", timedStats.gctimes => "gctimes")
#     checkState(!isempty(timedStatsField), "TimedStats object $(timedStats.name) has no recorded $(fields[timedStatsField]) values")
#     fieldMean = timedStatsField |> mean
#     return Dict(
#                 "$(fields[timedStatsField])Avg" => fieldMean,
#                 "$(fields[timedStatsField])Median" => median(timedStatsField),
#                 "$(fields[timedStatsField])StDev" => stdm(timedStatsField, fieldMean),
#                 "$(fields[timedStatsField])Variance" => varm(timedStatsField, fieldMean)
#                 )
# end
#
# timedStatsAnalysis(timedStats::TimedStats, timeStatsField::Vector{GC_Diff}) = timedStatsMemallocAnalysis(timedStats)

function timedStatsAnalysis(timedStats::TimedStats, timedStatsFieldName::TimedStatsFieldName)
    if timedStatsFieldName == MEMALLOCS
        return timedStatsMemallocAnalysis(timedStats)
    end
    # checkState(timedStatsFieldName == "times" || timedStatsFieldName == "bytes" || timedStatsFieldName == "gctimes", """ "$timedStatsFieldName" is not a valid TimedStats field name.
    # valid field names are: "times", "bytes", "gctimes", MEMALLOCS """)

    fields = Dict(TIMES => timedStats.times, BYTES => timedStats.bytes, GCTIMES => timedStats.gctimes)
    checkState(haskey(fields, timedStatsFieldName), """ '$timedStatsFieldName' is not a valid TimedStats field name.
    valid field names are: TIMES, BYTES, GCTIMES, MEMALLOCS """)
    checkState(!isempty(fields[timedStatsFieldName]), "TimedStats object $(timedStats.name) has no recorded $(timedStatsFieldName |> lowercase) values")
    fieldMean = fields[timedStatsFieldName] |> mean

    return Dict(
                "$(timedStatsFieldName |> lowercase)Avg" => fieldMean,
                "$(timedStatsFieldName |> lowercase)Median" => median(fields[timedStatsFieldName]),
                "$(timedStatsFieldName |> lowercase)StDev" => stdm(fields[timedStatsFieldName], fieldMean),
                "$(timedStatsFieldName |> lowercase)Variance" => varm(fields[timedStatsFieldName], fieldMean)
                )
end
