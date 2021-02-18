// vim: set ft=glsl:
out vec4 out_Color;
in mediump vec2 qt_TexCoord0;
// gravity property: North (1), West (4), East (3), South (2)
uniform int gravity;
uniform float qt_Opacity;
uniform bool inversion;

vec2 getCoord() {
    switch(gravity) {
    case 1:
        return vec2(inversion?(1-qt_TexCoord0.x): qt_TexCoord0.x,1-qt_TexCoord0.y);
    case 2:
        return vec2(inversion?(1-qt_TexCoord0.x):qt_TexCoord0.x,qt_TexCoord0.y);
    case 3:
        return vec2(inversion?qt_TexCoord0.y:(1-qt_TexCoord0.y),1-qt_TexCoord0.x);
    case 4:
        return vec2(inversion?qt_TexCoord0.y:(1-qt_TexCoord0.y),qt_TexCoord0.x);
    }
}

void main() {
    mainImage( out_Color,floor(getCoord()*iResolution.xy) );
}
