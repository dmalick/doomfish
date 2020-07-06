#version 330 core

in vec3 Color;

uniform vec3 triangleColor;

out vec4 outColor;

void main(){
    outColor = vec4(Color, 1.0);
}
