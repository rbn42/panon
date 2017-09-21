#version 400
in vec4 a_position;
out vec2 v_position;

void main()
{
    gl_Position = a_position;
    v_position.x= (a_position.x+1)/2;
    v_position.y= (a_position.y+1)/2;
}
