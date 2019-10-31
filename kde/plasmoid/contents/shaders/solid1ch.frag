#version 130
uniform sampler2D tex1;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

void main()
{
    vec4 sample1= texture(tex1, vec2(qt_TexCoord0.x,0.5)) ;
    float h=qt_TexCoord0.y;
    vec3 rgb=getRGB(qt_TexCoord0.x);

    out_Color=vec4(0.001,0.001,0.001,0.001);
    float max_=sample1.g*.5+sample1.r*.5;
    if(1.-max_<=h && h <=1.)
        out_Color=vec4(rgb*1.,1.);
}
