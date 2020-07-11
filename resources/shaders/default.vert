#version 330 core

in vec2 positionOffset;
in vec2 txrPositionIn

uniform vec2 position;

out vec2 txrPosition;

void main(){
    gl_Position = vec4( position + positionOffset, 0, 1 );
    txrPosition = txrPositionIn;
}
