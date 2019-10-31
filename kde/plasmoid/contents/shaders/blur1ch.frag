#version 130
uniform sampler2D tex1;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

void main()
{
    float px_step=0.0005;
    out_Color.rgba=vec4(0,0,0,0);
    for(int i=-5; i<5; i++) {
        float x=qt_TexCoord0.x+i*px_step;
        vec4 sample1= texture(tex1, vec2(x,0.5)) ;
        vec3 rgb=getRGB(x+i*px_step);

        float max_=sample1.g*.5+sample1.r*.5;
        float h=qt_TexCoord0.y;
        if(1.-max_<=h && h <=1.)
            out_Color+=vec4(rgb*1.,1.);
    }
    out_Color=out_Color/10.0;
}
