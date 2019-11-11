#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    vec4 sample1= texture(iChannel0, vec2(0.5*fragCoord.x/iResolution.x,0)) ;

    fragColor=vec4(0,0,0,0);

    int max_=int(sample1.r*iResolution.y)+1;
    int min_=int(sample1.r*iResolution.y)-1;

    if(min_<=fragCoord.y)
        if(fragCoord.y  <=max_) {
            fragColor.rgb=getRGB(fragCoord.x/iResolution.x);
            fragColor.a=1;
        }
}
