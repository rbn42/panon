#version 130
uniform sampler2D tex1;
out vec4 out_Color;

void main()
{
    vec4 sample1= texture(tex1, vec2(getCoord().x,1/8.)) ;
    float h=getCoord().y;
    vec3 rgb=getRGB(getCoord().x);

    out_Color=vec4(0.001,0.001,0.001,0.001);
    float max_=sample1.g*.5+sample1.r*.5;
    if(1.-max_<=h && h <=1.)
        out_Color=vec4(rgb*1.,1.);
}
