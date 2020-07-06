include("/home/gil/doomfish/pseudointerface/interface/utils.jl")
include("StatsName.jl")


mutable struct TimeStats
    lastTime::Float64
    avgTime::Float64
    totalTimes::Int

    lastByteCt::Int
    avgByteCt::Float64
    totalByteCts::Int

    lastGCtime::Float64
    avgGCtime::Float64
    totalGCtimes::Int
end

TimeStats() = TimeStats( zeros( fieldcount(TimeStats) )... )


function updateStats!( stats::TimeStats, time::Float64, byteCt::Int, gctime::Float64 )
    stats.lastTime = time
    stats.avgTime = newAvg( time, stats.avgTime, stats.totalTimes )
    stats.totalTimes += 1

    stats.lastByteCt = byteCt
    stats.avgByteCt = newAvg( byteCt, stats.avgByteCt, stats.totalByteCts )
    stats.totalByteCts += 1

    stats.lastGCtime = gctime
    stats.avgGCtime = newAvg( gctime, stats.avgGCtime, stats.totalGCtimes )
    stats.totalGCtimes += 1
end

function updateStats!( stats::TimeStats, returnval, time::Float64, byteCt::Int, gctime::Float64, memallocs )
    updateStats!( stats, time, byteCt, gctime )
    return returnval
end

newAvg( newVal, oldAvg, totalPriorVals ) = return ( (totalPriorVals * oldAvg) + newVal ) / ( totalPriorVals + 1 )
