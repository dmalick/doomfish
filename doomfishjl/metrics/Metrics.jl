include("Counters.jl")
include("Stats.jl")
include("TimeStats.jl")
include("StatsName.jl")


# most of the time, outside code will call @collectstats as opposed to updateStats!() for recording performance statistics.
# main exception is the TextureRegistry, which accumulates TEXTURE_PRELOAD_ADVISING stats in a queue
# and dumps them to the Metrics struct when there's a lull in the action.


mutable struct Metrics
    counters::Counters
    timeStats::Dict{ StatsName, TimeStats }
    statContainers::Dict{ StatsName, Stats }
end
# keeping this an outer constructor for now b/c we eventually may want to load up
# previously acquired Metrics from a snapshot.
Metrics() = Metrics( Counters(), Dict{ StatsName, TimeStats }(), Dict{ StatsName, Stats }() )


# this one essentially never gets called in external code, but gets called in other methods of updateStats!()
function updateStats!(metrics::Metrics, statsName::StatsName, time, bytes, gctime, memallocs)
    if !haskey(metrics.statContainers, statsName)
        metrics.statContainers[statsName] = Stats(statsName)
    end
    push!( metrics.statContainers[statsName].times, time )
    push!( metrics.statContainers[statsName].bytes, bytes )
    push!( metrics.statContainers[statsName].gctimes, gctime )
    push!( metrics.statContainers[statsName].memallocs, memallocs )
end

# these do get called externally
function updateStats!(metrics::Metrics, statsName::StatsName, returnVal, time, bytes, gctime, memallocs)
    updateStats!(metrics, statsName, time, bytes, gctime, memallocs)
    return returnVal
end
updateStats!(metrics::Metrics, statsName::StatsName, stats::Tuple{Any,Float64,Int64,Float64,GC_Diff}) = return updateStats!(metrics, statsName, stats...)
updateStats!(metrics::Metrics, statsName::StatsName, stats::Tuple{Float64,Int64,Float64,GC_Diff}) = return updateStats!(metrics, statsName, stats...)


#  call format for @collectstats is
# @collectstats <StatsName> ftn(),
# @collectstats @macro ..., or
# @collectstats <StatsName> begin ... end
# anything else we might want to call it on should be wrapped in a begin block.
# macro collectstats(statsName, body)
#
#     checkArgument( statsName isa Symbol, "first argument to @collectstats must be a StatsName, got $statsName" )
#     firstArg = eval(statsName)
#     checkArgument( firstArg isa StatsName, "first argument to @collectstats must be a StatsName, got $firstArg" )
#     checkArgument( body isa Expr , "second argument to @collectstats takes either a function call, a begin block, or another macro call; got $body (a symbol)" )
#     checkArgument( body.head in (:call, :block, :macrocall), "second argument to @collectstats takes either a function call or a begin block, or another macro call; got $body (a $(body.head))" )
#
#     # WARNING: the `$metrics` below refers to the var `metrics` of type Metrics, which should exist in the global scope.
#     # yeah yeah
#
#     # the @timed macro returns a tuple of (returnval, time, bytes, gctime, memallocs), which the whole Stats struct is built around,
#     # w/ returnval being the result of the expression @timed operates on.
#     # updateStats!() returns this value.
#     # So the @collectstats macro ultimately returns the result of the expression it operates on, as it should.
#
#     return esc( :( updateStats!( metrics, $statsName, @timed $body ) ) )
# end
