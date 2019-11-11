#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragCoord=fragCoord/iResolution.xy;
    vec4 sample1= texture(iChannel1, vec2(fragCoord.x,0)) ;
    float h=fragCoord.y;
    vec3 rgb=getRGB(fragCoord.x);

    fragColor=vec4(0.001,0.001,0.001,0.001);
    float max_=sample1.g*.5+sample1.r*.5;
    if(max_>h )
        fragColor=vec4(rgb*1.,1.);
}
