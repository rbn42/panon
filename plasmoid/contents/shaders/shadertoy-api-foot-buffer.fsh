// vim: set ft=glsl:
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 out_Color;

void main() {
    mainImage(out_Color, floor(qt_TexCoord0 * iResolution.xy));
}
