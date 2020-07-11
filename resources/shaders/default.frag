#version 330 core

in vec2 txrPosition;

uniform sampler2D txr;

out vec4 outColor;

void main(){

    outColor = texture(txr, txrPosition);
}
