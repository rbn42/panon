uniform sampler2D tex1;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

void main()
{
    int bar_all=128;
    int fill=2;
    int empty=1;

    int x_i=int(qt_TexCoord0.x*bar_all*(fill+empty));
    float h=1-qt_TexCoord0.y;

    out_Color=vec4(0,0,0,0);
    if(x_i%(fill+empty)<fill){
        float x=x_i/(fill+empty) /1.0/bar_all;
        vec4 sample1= texture(tex1, vec2(x,0.5)) ;
        vec3 rgb=getRGB(x);

        float max_=sample1.g*.5+sample1.r*.5;
        if(h<=max_)
            out_Color=vec4(rgb*1.,1.);

        float max_2=sample1.b*.5+sample1.a*.5;
        if(max_2-0.03<=h && h <=max_2)
            out_Color=vec4(rgb*1.,1.);
    }
}
