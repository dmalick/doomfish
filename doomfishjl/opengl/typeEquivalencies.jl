using ModernGL

typeEquivalencies = Dict(

     true => GL_TRUE,
     false => GL_FALSE,

     Float16 => GL_HALF_FLOAT,
     Float32 => GL_FLOAT,
     Float64 => GL_DOUBLE,

     Int16 => GL_SHORT,
     Int32 => GL_INT,
     UInt8 => GL_BYTE,
     UInt16 => GL_UNSIGNED_SHORT,
     UInt32 => GL_UNSIGNED_INT,

    )
