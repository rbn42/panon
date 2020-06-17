#version 130
uniform sampler2D bufferOutput;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;
void main() {
    out_Color=texture(bufferOutput,qt_TexCoord0);
}
