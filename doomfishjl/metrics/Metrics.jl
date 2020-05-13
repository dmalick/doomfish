include("Counters.jl")
include("TimedStats.jl")
include("TimedStatsName.jl")


mutable struct Metrics
    counters::Counters
    timedStatContainers::Dict{TimedStatsName, TimedStats}
end


function updateTimedStats!(metrics::Metrics, timedStatsName::TimedStatsName, time, bytes, gctime, memallocs)
    if !haskey(metrics.timedStatContainers, timedStatsName)
        metrics.timedStatContainers[timedStatsName] = TimedStats(timedStatsName)
    end
    push!( metrics.timedStatContainers[timedStatsName].times, time )
    push!( metrics.timedStatContainers[timedStatsName].bytes, bytes )
    push!( metrics.timedStatContainers[timedStatsName].gctimes, gctime )
    push!( metrics.timedStatContainers[timedStatsName].memallocs, memallocs )
end

function updateTimedStats!(metrics::Metrics, timedStatsName::TimedStatsName, returnVal, time, bytes, gctime, memallocs)
    updateTimedStats!(metrics, timedStatsName, time, bytes, gctime, memallocs)
    return returnVal
end

updateTimedStats!(metrics::Metrics, timedStatsName::TimedStatsName, stats::Tuple{Any,Float64,Int64,Float64,GC_Diff}) = return updateTimedStats!(metrics, timedStatsName, stats...)
updateTimedStats!(metrics::Metrics, timedStatsName::TimedStatsName, stats::Tuple{Float64,Int64,Float64,GC_Diff}) = return updateTimedStats!(metrics, timedStatsName, stats...)


macro updateTimedStats!(metrics, timedStatsName, stats)
    m = eval(metrics)
    t = eval(timedStatsName)
    s = eval(stats)
    updateTimedStats!(m, t, s)
end
