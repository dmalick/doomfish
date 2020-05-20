

function A(a, b)
    βs = Vector{Int}()
    for α in a
        β = α^2 + α*b + b^2
        push!(βs, β)
    end
    return βs
end

B(a, b) = return [α^2 + α*b + b^2 for α in a]

C(a, b) = map( α-> (α^2 + α*b + b^2), a )
