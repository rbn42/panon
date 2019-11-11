#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragCoord=fragCoord/iResolution.xy;
    float px_step=0.0005;
    fragColor.rgba=vec4(0,0,0,0);
    for(int i=-5; i<5; i++) {
        float x=fragCoord.x+i*px_step;
        vec4 sample1= texture(iChannel1, vec2(x,0)) ;
        vec3 rgb=getRGB(x+i*px_step);

        float max_=sample1.g*.5+sample1.r*.5;
        float h=fragCoord.y;
        if(max_>h )
            fragColor+=vec4(rgb*1.,1.);
    }
    fragColor=fragColor/10.0;
}
