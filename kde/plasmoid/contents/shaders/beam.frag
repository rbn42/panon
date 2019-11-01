#version 130
uniform sampler2D tex1;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

void main()
{
    vec4 sample1= texture(tex1, vec2(qt_TexCoord0.x,1/8.)) ;
    float h=qt_TexCoord0.y;
    vec3 rgb=getRGB(qt_TexCoord0.x);

    float a=(sample1.r+sample1.g)/2.0;
    out_Color=vec4(rgb*a,a);
}
