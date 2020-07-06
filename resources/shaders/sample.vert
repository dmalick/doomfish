#version 330 core

in vec2 position;
in vec3 inColor;

out vec3 color;

void main() {
  gl_Position = vec4(position, 0.0, 1.0);
  color = inColor;
}
