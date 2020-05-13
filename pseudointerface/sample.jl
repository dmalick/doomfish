include("interface.jl")
include("checks.jl")


# define an interface w/ the @interface macro, similar to using the @enum macro

@interface InterestingSampler begin
    α::String
    β::Int
end

# declare abstract methods w/ @abstractMethod

@abstractMethod( InterestingSampler, getInterest )
@abstractMethod( InterestingSampler, getSample )

# put stuff here

# when done call @checkVarsImplemented(abstractType) and @checkMethodsImplemented(abstractType) to enforce the rules

@checkVarsImplemented( InterestingSampler )
@checkMethodsImplemented( InterestingSampler )
