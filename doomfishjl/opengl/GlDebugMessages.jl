using ModernGL, GLAbstraction, GLFW

# the original betamax code is again thick w/ javaisms and library calls and may not be translatable.
# for the time being I've left this functionality out of GlWindow.jl

# struct GlDebugMessages
#     id::UInt32
#     source::String
#     type::String
#     severity::String
#     message::String
#     category::String
# end


function getDebugTrait(traits::Dict{UInt32, String}, trait::UInt32, traitName::String)
    return haskey(traits, trait) ? get(traits, trait) : "UNKNOWN DEBUG $traitName"
end

function getDebugSource(source::UInt32)
    sources = Dict(GL_DEBUG_SOURCE_API => "API",
                   GL_DEBUG_SOURCE_WINDOW_SYSTEM =>"WINDOW SYSTEM",
                   GL_DEBUG_SOURCE_SHADER_COMPILER => "SHADER COMPILER",
                   GL_DEBUG_SOURCE_THIRD_PARTY => "THIRD PARTY",
                   GL_DEBUG_SOURCE_APPLICATION => "APPLICATION",
                   GL_DEBUG_SOURCE_OTHER => "OTHER"
                   )
    getDebugTrait(sources, source, "SOURCE")
end

function getDebugType(type::UInt32)
    types = Dict(GL_DEBUG_TYPE_ERROR => "ERROR",
                 GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR => "DEPRECATED BEHAVIOR",
                 GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR => "UNDEFINED BEHAVIOR",
                 GL_DEBUG_TYPE_PORTABILITY => "PORTABILITY",
                 GL_DEBUG_TYPE_PERFORMANCE => "PERFORMANCE",
                 GL_DEBUG_TYPE_OTHER => "OTHER",
                 GL_DEBUG_TYPE_MARKER => "MARKER"
                 )
    getDebugTrait(types, type, "TYPE")
end

function getDebugSeverity(severity::UInt32)
    severities = Dict(GL_DEBUG_SEVERITY_HIGH => "HIGH",
                      GL_DEBUG_SEVERITY_MEDIUM => "MEDIUM",
                      GL_DEBUG_SEVERITY_LOW => "LOW",
                      GL_DEBUG_SEVERITY_NOTIFICATION => "NOTIFICATION"
                     )
    getDebugTrait(severities, severity, "SEVERITY")
end

function getSourceARB(source::UInt32)
    sources = Dict(GL_DEBUG_SOURCE_API_ARB => "API",
                   GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB => "WINDOW SYSTEM",
                   GL_DEBUG_SOURCE_SHADER_COMPILER_ARB => "SHADER COMPILER",
                   GL_DEBUG_SOURCE_THIRD_PARTY_ARB => "THIRD PARTY",
                   GL_DEBUG_SOURCE_APPLICATION_ARB => "APPLICATION",
                   GL_DEBUG_SOURCE_OTHER_ARB => "OTHER"
                   )
    getDebugTrait(sources, source, "SOURCE ARB")
end

function getTypeARB(type::UInt32)
    types = Dict(
            GL_DEBUG_TYPE_ERROR_ARB => "ERROR",
			GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB => "DEPRECATED BEHAVIOR",
			GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB => "UNDEFINED BEHAVIOR",
			GL_DEBUG_TYPE_PORTABILITY_ARB => "PORTABILITY",
			GL_DEBUG_TYPE_PERFORMANCE_ARB => "PERFORMANCE",
			GL_DEBUG_TYPE_OTHER_ARB => "OTHER"
    )
	getDebugTrait(types, type, "TYPE ARB")

end

function getSeverityARB(severity::UInt32)
    severities = Dict(
        GL_DEBUG_SEVERITY_HIGH_ARB => "HIGH",
        GL_DEBUG_SEVERITY_MEDIUM_ARB => "MEDIUM",
        GL_DEBUG_SEVERITY_LOW_ARB => "LOW",
        )
    getDebugTrait(severities, severity, "SEVERITY ARB")
end

function getCategoryAMB(category::UInt32)
    categories = Dict(
        GL_DEBUG_CATEGORY_API_ERROR_AMD => "API ERROR",
        GL_DEBUG_CATEGORY_WINDOW_SYSTEM_AMD => "WINDOW SYSTEM",
        GL_DEBUG_CATEGORY_DEPRECATION_AMD => "DEPRECATION",
        GL_DEBUG_CATEGORY_UNDEFINED_BEHAVIOR_AMD => "UNDEFINED BEHAVIOR",
        GL_DEBUG_CATEGORY_PERFORMANCE_AMD => "PERFORMANCE",
        GL_DEBUG_CATEGORY_SHADER_COMPILER_AMD => "SHADER COMPILER",
        GL_DEBUG_CATEGORY_APPLICATION_AMD => "APPLICATION",
        GL_DEBUG_CATEGORY_OTHER_AMD => "OTHER",
    )
    getDebugTrait(categories, category, "CATEGORY AMB")
end

function getSeverityAMD(severity::UInt32)
    severities = Dict(
           GL_DEBUG_SEVERITY_HIGH_AMD => "HIGH",
           GL_DEBUG_SEVERITY_MEDIUM_AMD => "MEDIUM",
           GL_DEBUG_SEVERITY_LOW_AMD => "LOW",
        )
    getDebugTrait(severities, severity, "SEVERITY AMD")
end
