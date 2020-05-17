include("Counters.jl")
include("Stats.jl")
include("StatsName.jl")


mutable struct Metrics
    counters::Counters
    statContainers::Dict{StatsName, Stats}
end


function updateStats!(metrics::Metrics, statsName::StatsName, time, bytes, gctime, memallocs)
    if !haskey(metrics.statContainers, statsName)
        metrics.statContainers[statsName] = Stats(statsName)
    end
    push!( metrics.statContainers[statsName].times, time )
    push!( metrics.statContainers[statsName].bytes, bytes )
    push!( metrics.statContainers[statsName].gctimes, gctime )
    push!( metrics.statContainers[statsName].memallocs, memallocs )
end

function updateStats!(metrics::Metrics, statsName::StatsName, returnVal, time, bytes, gctime, memallocs)
    updateStats!(metrics, statsName, time, bytes, gctime, memallocs)
    return returnVal
end

updateStats!(metrics::Metrics, statsName::StatsName, stats::Tuple{Any,Float64,Int64,Float64,GC_Diff}) = return updateStats!(metrics, statsName, stats...)
updateStats!(metrics::Metrics, statsName::StatsName, stats::Tuple{Float64,Int64,Float64,GC_Diff}) = return updateStats!(metrics, statsName, stats...)


macro updateStats!(metrics, statsName, stats)
    m = eval(metrics)
    t = eval(statsName)
    s = eval(stats)
    updateStats!(m, t, s)
end
