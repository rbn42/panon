#version 130
uniform sampler2D tex1;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

void main()
{
    vec4 sample1= texture(tex1, vec2(qt_TexCoord0.x,1/8.)) ;
    float h=qt_TexCoord0.y;
    vec3 rgb=getRGB(qt_TexCoord0.x);

    float[] rels=float[5](4.,3.,2.,1.,.5);
    float[] alphas=float[5](.1,.2,.3,.5,1.);
    //float[] rels=float[1](1.0);
    //float[] alphas=float[1](1.0);
    out_Color=vec4(0.001,0.001,0.001,0.001);
    for (int i=0;i<5;i++){
        float r=rels[i];
        float a=alphas[i];
        float max_=.5+sample1.r*r;
        float min_=.5-sample1.g*r;
        if(min_<=h && h <=max_)
            out_Color=vec4(rgb*a,a);
    }
}
