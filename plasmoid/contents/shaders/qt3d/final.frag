#version 130
uniform sampler2D imageOutput;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

void main() {
    out_Color.a=1;
    if(qt_TexCoord0.x<0.5)
        out_Color.rgb=texture(imageOutput,vec2(qt_TexCoord0.x*2,1-qt_TexCoord0.y)).rgb;
    else
        out_Color.rgb=texture(imageOutput,vec2(qt_TexCoord0.x*2-1,1-qt_TexCoord0.y)).aaa;
}
