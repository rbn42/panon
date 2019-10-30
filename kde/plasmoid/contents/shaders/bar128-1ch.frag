uniform sampler2D tex1;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

void main()
{
    int bar_all=128;
    int fill=2;
    int empty=1;

    int x_i=int(qt_TexCoord0.x*bar_all*(fill+empty));

    out_Color=vec4(0,0,0,0);
    if(x_i%(fill+empty)<fill){
        float x=x_i/(fill+empty) /1.0/bar_all;
        vec4 sample1= texture(tex1, vec2(x,0.5)) ;
        float h=qt_TexCoord0.y;
        vec3 rgb=getRGB(x);

        float max_=sample1.g*.5+sample1.r*.5;
        if(1.-max_<=h && h <=1.)
            out_Color=vec4(rgb*1.,1.);
    }
}
