

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
