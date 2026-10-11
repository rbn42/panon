// vim: set ft=glsl:
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 out_Color;
// gravity property: North (1), South (2), East (3), West (4)
uniform int coord_gravity;
uniform int coord_inversion;

vec2 getCoord() {
    bool inversion = coord_inversion != 0;
    switch(coord_gravity) {
    case 2:
        return vec2(inversion ? (1.0 - qt_TexCoord0.x) : qt_TexCoord0.x, qt_TexCoord0.y);
    case 3:
        return vec2(inversion ? qt_TexCoord0.y : (1.0 - qt_TexCoord0.y), 1.0 - qt_TexCoord0.x);
    case 4:
        return vec2(inversion ? qt_TexCoord0.y : (1.0 - qt_TexCoord0.y), qt_TexCoord0.x);
    default:
        return vec2(inversion ? (1.0 - qt_TexCoord0.x) : qt_TexCoord0.x, 1.0 - qt_TexCoord0.y);
    }
}

void main() {
    mainImage(out_Color, floor(getCoord() * iResolution.xy));
}
