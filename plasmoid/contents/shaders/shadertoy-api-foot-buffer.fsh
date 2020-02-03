// vim: set ft=glsl:
out vec4 out_Color;
in mediump vec2 qt_TexCoord0;

vec2 getCoord() {
    return qt_TexCoord0;
}

void main() {
    mainImage( out_Color,getCoord()*iResolution.xy );
}
