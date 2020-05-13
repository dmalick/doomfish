using ModernGL, GLAbstraction

struct VBO
    handle::UInt32
end

function getVBO()
    return VBO(glGenBuffers())
end

function bindVBO(vbo::VBO, target::UInt32)
    glBindBuffer(target, vbo.handle)
end

function bindAndLoadVBO(vbo::VBO, target::UInt32, usage::UInt32, data::Array)
    bindVBO(vbo, target)
    glBufferData(target, sizeof(data), data, usage)
end
