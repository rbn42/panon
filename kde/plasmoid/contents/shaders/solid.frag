#version 130
uniform sampler2D tex1;
out vec4 out_Color;

void main()
{
    // A list of available data channels
    // Spectrum data
    vec4 sample1= texture(tex1, vec2(getCoord().x,1/8.)) ;
    // Maximum spectrum data in recent history
    // vec4 sample2= texture(tex1, vec2(getCoord().x,3/8.)) ;
    // Reserved data channel
    // vec4 sample3= texture(tex1, vec2(getCoord().x,5/8.)) ;
    // Reserved data channel
    // vec4 sample4= texture(tex1, vec2(getCoord().x,7/8.)) ;

    // Color defined by user configuration
    vec3 rgb=getRGB(getCoord().x);

    // Background color
    out_Color=vec4(0.001,0.001,0.001,0.001);
    // Right channel
    float max_=.5+sample1.g*.5;
    // Left channel
    float min_=.5-sample1.r*.5;

    float h=getCoord().y;
    if(min_<=h && h <=max_)
        out_Color=vec4(rgb,1.);
}
