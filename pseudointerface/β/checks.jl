import Base.empty
include("conflicts.jl")


function checkState(state::Bool, errorMessage::String="invalid state: $state")
    if !state
        error(errorMessage)
    end
end

function checkArgument(conditional::Bool, errorMessage::String="$conditional not met")
    if !conditional
        throw(ArgumentError(errorMessage))
    end
end

checkArgument(arg, f::Function, errorMessage::String="$f(arg) returned false") = checkArgument( f(arg), errorMessage)
