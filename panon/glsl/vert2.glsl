#version 400
out vec2 v_position;
in vec2 vert;

void main() {
    gl_Position = vec4(vert, 0.0, 1.0);
    v_position.x= (vert.x+1)/2;
    v_position.y= (vert.y+1)/2;
}
