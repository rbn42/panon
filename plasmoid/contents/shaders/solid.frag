#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragCoord=fragCoord/iResolution.xy;
    // A list of available data channels
    // Spectrum data
    vec4 sample1= texture(iChannel1, vec2(fragCoord.x,0)) ;
    // Wave data channel
    // vec4 sample3= texture(iChannel0, vec2(fragCoord.x,0)) ;

    // Color defined by user configuration
    vec3 rgb=getRGB(fragCoord.x);

    // Background color
    fragColor=vec4(0.001,0.001,0.001,0.001);
    // Right channel
    float max_=.5+sample1.g*.5;
    // Left channel
    float min_=.5-sample1.r*.5;

    float h=fragCoord.y;
    if(min_<=h && h <=max_)
        fragColor=vec4(rgb,1.);
}
