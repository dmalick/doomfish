#version 330 core

in vec2 position;
in vec3 inColor;

uniform float up;
uniform float right;
uniform float down;
uniform float left;

out vec3 color;

void main(){
    gl_Position = vec4( position.x + left + right,
                        position.y + up + down,
                    0, 1);
    color = inColor;
}
