#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    if(fragCoord.x<iResolution.x*.5){
        fragColor= texelFetch(iChannel2,ivec2(fragCoord.x,fragCoord.y-1) , 0);
        if(fragCoord.y<1){
            float x=fragCoord.x*2/iResolution.x;
            fragColor= texture(iChannel1, vec2(x,0));
        }
    }else{
        fragColor= texelFetch(iChannel2,ivec2(fragCoord.x,fragCoord.y-1) , 0);
        if(fragCoord.y<1){
            float x=fragCoord.x*2/iResolution.x-1;
            fragColor= texture(iChannel1, vec2(x,0));
            fragColor-= texelFetch(iChannel2,ivec2(fragCoord.x-iResolution.x*.5,0) , 0);
            fragColor-=0.4;
            fragColor*=1000;
        }
    }
}
