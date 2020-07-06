using ModernGL

@enum GlErrorCode begin

    INVALID_ENUM =                  GL_INVALID_ENUM                  # UInt32( 0x500 )
    INVALID_VALUE =                 GL_INVALID_VALUE                 # UInt32( 0x501 )
    INVALID_OPERATION =             GL_INVALID_OPERATION             # UInt32( 0x502 )
    STACK_OVERFLOW =                GL_STACK_OVERFLOW                # UInt32( 0x503 )
    STACK_UNDERFLOW =               GL_STACK_UNDERFLOW               # UInt32( 0x504 )
    OUT_OF_MEMORY =                 GL_OUT_OF_MEMORY                 # UInt32( 0x505 )
    INVALID_FRAMEBUFFER_OPERATION = GL_INVALID_FRAMEBUFFER_OPERATION # UInt32( 0x506 )

end
