#version 130
uniform sampler2D tex1;
out vec4 out_Color;

void main()
{
    vec4 sample1= texture(tex1, vec2(getCoord().x,1/8.)) ;
    float h=getCoord().y;
    vec3 rgb=getRGB(getCoord().x);

    float a=(sample1.r+sample1.g)/2.0;
    out_Color=vec4(rgb*a,a);
}
